#!/usr/bin/env python3
"""
AI Pair Programmer - Get second opinions from multiple AI providers.

Supports: Grok (xAI), ChatGPT (OpenAI), Gemini (Google)

Usage:
    python3 pair_review.py --provider grok "Your plan or code to review"
    python3 pair_review.py --provider gemini,chatgpt --files file1.py file2.py
    python3 pair_review.py --provider all "Review with all configured providers"
"""

import argparse
import json
import os
import sys
import concurrent.futures
from typing import Callable

# Add the script directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from providers import (
    get_provider,
    get_available_providers,
    get_configured_providers,
    ProviderResult
)
from prompts import (
    build_system_prompt,
    build_user_message,
    LANG_MAP
)


def format_multi_files(file_paths: list[str]) -> tuple[str, list[str]]:
    """Read and format multiple files with markdown code blocks.

    Returns:
        Tuple of (formatted content, list of warnings/errors)
    """
    formatted = []
    warnings = []
    for path in file_paths:
        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
                if not content.strip():
                    warnings.append(f"File '{path}' is empty")
                    formatted.append(f"File: {path} (empty)\n")
                    continue
                ext = os.path.splitext(path)[1].lower()
                lang = LANG_MAP.get(ext, "text")
                formatted.append(f"File: {path}\n```{lang}\n{content}\n```\n")
        except FileNotFoundError:
            warnings.append(f"File not found: {path}")
            formatted.append(f"File: {path} (not found)\n")
        except PermissionError:
            warnings.append(f"Permission denied: {path}")
            formatted.append(f"File: {path} (permission denied)\n")
        except Exception as e:
            warnings.append(f"Error reading '{path}': {e}")
            formatted.append(f"File: {path} (error: {e})\n")
    return "\n".join(formatted), warnings


def estimate_tokens(text: str) -> int:
    """Rough token estimate (~1.3 tokens per word)."""
    return int(len(text.split()) * 1.3)


def print_content_error(args, content_source: str = None):
    """Print detailed error message when content is missing or empty."""
    print("\n" + "=" * 60, file=sys.stderr)
    print("ERROR: No content to review", file=sys.stderr)
    print("=" * 60, file=sys.stderr)

    # Show what was received
    print("\nArguments received:", file=sys.stderr)
    print(f"  --content (positional): {repr(args.content) if args.content is not None else '(not provided)'}", file=sys.stderr)
    print(f"  --file:                 {args.file if args.file else '(not provided)'}", file=sys.stderr)
    print(f"  --files:                {args.files if args.files else '(not provided)'}", file=sys.stderr)
    print(f"  --proposal:             {repr(args.proposal[:50] + '...') if args.proposal and len(args.proposal) > 50 else repr(args.proposal) if args.proposal else '(not provided)'}", file=sys.stderr)
    print(f"  stdin:                  {'(has data)' if not sys.stdin.isatty() else '(no data)'}", file=sys.stderr)

    if content_source:
        print(f"\nContent source '{content_source}' was empty or whitespace-only.", file=sys.stderr)

    print("\nTo fix this, provide content using ONE of:", file=sys.stderr)
    print("  1. Positional argument:  python3 pair_review.py --provider grok 'Your plan here'", file=sys.stderr)
    print("  2. File:                 python3 pair_review.py --provider grok --file path/to/file.py", file=sys.stderr)
    print("  3. Multiple files:       python3 pair_review.py --provider grok --files file1.py file2.py", file=sys.stderr)
    print("  4. Proposal (for plans): python3 pair_review.py --provider grok --proposal 'Your approach'", file=sys.stderr)
    print("  5. Stdin:                echo 'content' | python3 pair_review.py --provider grok", file=sys.stderr)

    print("\nFor architecture/plan reviews without code files, use --proposal:", file=sys.stderr)
    print("  python3 pair_review.py --provider grok \\", file=sys.stderr)
    print("    --context 'User wants X' \\", file=sys.stderr)
    print("    --proposal 'My approach is Y because Z'", file=sys.stderr)
    print("=" * 60 + "\n", file=sys.stderr)


def parse_providers(provider_str: str) -> list[str]:
    """Parse provider string into list of provider names."""
    if not provider_str:
        return []

    provider_str = provider_str.lower().strip()

    # Handle "all" to use all configured providers
    if provider_str == "all":
        configured = get_configured_providers()
        if not configured:
            print("\n" + "=" * 60, file=sys.stderr)
            print("ERROR: No AI providers configured", file=sys.stderr)
            print("=" * 60, file=sys.stderr)
            print("\nYou requested --provider all but no API keys are set.", file=sys.stderr)
            print("\nTo fix this, set at least one API key environment variable:", file=sys.stderr)
            print("  export XAI_API_KEY='your-key'      # for Grok", file=sys.stderr)
            print("  export OPENAI_API_KEY='your-key'  # for ChatGPT", file=sys.stderr)
            print("  export GEMINI_API_KEY='your-key'  # for Gemini", file=sys.stderr)
            print("\nOr use a specific provider if you have its key:", file=sys.stderr)
            print("  --provider grok    (requires XAI_API_KEY)", file=sys.stderr)
            print("  --provider chatgpt (requires OPENAI_API_KEY)", file=sys.stderr)
            print("  --provider gemini  (requires GEMINI_API_KEY)", file=sys.stderr)
            print("=" * 60 + "\n", file=sys.stderr)
            sys.exit(1)
        return [p.name.lower() for p in configured]

    # Parse comma-separated list
    providers = [p.strip() for p in provider_str.split(",") if p.strip()]
    return providers


def call_provider(
    provider_name: str,
    system_prompt: str,
    user_message: str,
    model: str | None
) -> ProviderResult:
    """Call a single provider and return result."""
    try:
        provider = get_provider(provider_name)
        # Customize system prompt with provider name
        customized_prompt = system_prompt.replace(
            "You are {provider_name}",
            f"You are {provider.get_system_prompt_name()}"
        )
        return provider.call_api(customized_prompt, user_message, model)
    except ValueError as e:
        return ProviderResult(
            success=False,
            provider_name=provider_name,
            error=str(e)
        )


def format_result(result: ProviderResult, review_type: str, show_json: bool = False) -> str:
    """Format a provider result for display."""
    if show_json:
        return json.dumps({
            "provider": result.provider_name,
            "success": result.success,
            "response": result.response if result.success else None,
            "error": result.error if not result.success else None,
            "model": result.model,
            "usage": result.usage
        }, indent=2)

    lines = []
    lines.append(f"## {result.provider_name}'s Feedback ({review_type.capitalize()} Review)")
    lines.append("")

    if result.success:
        lines.append(result.response)
        lines.append("")
        lines.append("---")
        if result.usage:
            u = result.usage
            total = u.get('total_tokens', 0)
            prompt = u.get('prompt_tokens', 0)
            completion = u.get('completion_tokens', 0)
            if total:
                lines.append(f"_Model: {result.model} | Tokens: {total} ({prompt} in / {completion} out)_")
    else:
        lines.append(f"**Error:** {result.error}")

    return "\n".join(lines)


def format_multi_results(results: list[ProviderResult], review_type: str) -> str:
    """Format multiple provider results for comparison."""
    lines = []
    lines.append("# AI Pair Programming Review")
    lines.append("")
    lines.append(f"_Consulted {len(results)} AI{'s' if len(results) > 1 else ''} for second opinions_")
    lines.append("")

    successful = [r for r in results if r.success]
    failed = [r for r in results if not r.success]

    for result in successful:
        lines.append(format_result(result, review_type))
        lines.append("")

    if failed:
        lines.append("## Errors")
        lines.append("")
        for result in failed:
            lines.append(f"- **{result.provider_name}**: {result.error}")
        lines.append("")

    if len(successful) > 1:
        lines.append("---")
        lines.append("")
        lines.append("## Synthesis Guidance")
        lines.append("")
        lines.append("As the lead architect, consider:")
        lines.append("- Where do the reviewers **agree**? High confidence in those points.")
        lines.append("- Where do they **disagree**? Evaluate each perspective against your context.")
        lines.append("- What unique insights does each bring?")
        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="AI Pair Programmer - get second opinions from AI providers",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Review with Grok
  python3 pair_review.py --provider grok \\
    --app-context ".NET MAUI app with MVVM" \\
    --context "Adding offline caching" \\
    --proposal "Use SQLite with repository pattern" \\
    --files src/Services/ApiService.cs

  # Review with multiple providers (parallel)
  python3 pair_review.py --provider grok,gemini,chatgpt \\
    --context "Architecture decision for auth" \\
    --proposal "Use OAuth2 with PKCE flow" \\
    --type architecture

  # Use all configured providers
  python3 pair_review.py --provider all \\
    --context "Code review for PR" \\
    --type code \\
    --file changes.cs

Available providers: grok (xAI), chatgpt/openai, gemini (Google)
Aliases: xai->grok, gpt->chatgpt, google->gemini
"""
    )

    # Provider selection
    parser.add_argument(
        "--provider", "-P",
        default="grok",
        help="Provider(s) to use: grok, chatgpt, gemini, or comma-separated list, or 'all'"
    )
    parser.add_argument(
        "--list-providers",
        action="store_true",
        help="List available providers and their configuration status"
    )

    # Context arguments
    context_group = parser.add_argument_group("pair programming context")
    context_group.add_argument(
        "--app-context", "-a",
        help="App/project context (e.g., '.NET MAUI app with MVVM, targeting iOS/Android')"
    )
    context_group.add_argument(
        "--context", "-c",
        help="Problem context - what the user asked or the goal"
    )
    context_group.add_argument(
        "--proposal", "-p",
        help="Claude's proposed solution or approach"
    )
    context_group.add_argument(
        "--considered", "-C",
        help="Approaches already tried or rejected (so reviewers don't suggest them)"
    )

    # Content arguments
    content_group = parser.add_argument_group("content to review")
    content_group.add_argument(
        "content",
        nargs="?",
        help="Direct content to review (plan, code, or description)"
    )
    content_group.add_argument(
        "--file", "-f",
        help="Read content from a file"
    )
    content_group.add_argument(
        "--files", "-F",
        nargs="+",
        help="Read and format multiple files for review"
    )

    # Review type arguments
    type_group = parser.add_argument_group("review type")
    type_group.add_argument(
        "--diff", "-d",
        action="store_true",
        help="Treat input as a git diff"
    )
    type_group.add_argument(
        "--summary", "-s",
        action="store_true",
        help="Treat input as a high-level summary"
    )
    type_group.add_argument(
        "--type", "-t",
        choices=["plan", "code", "architecture", "general"],
        default="general",
        help="Type of review (default: general)"
    )

    # Other options
    parser.add_argument(
        "--model", "-m",
        help="Override the model for all providers"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output raw JSON response"
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Show the full prompt being sent"
    )
    parser.add_argument(
        "--sequential",
        action="store_true",
        help="Run providers sequentially instead of in parallel"
    )

    args = parser.parse_args()

    # Handle --list-providers
    if args.list_providers:
        from providers.base import _CONFIG_PATH
        print("Available AI Providers:")
        print("")
        for name in get_available_providers():
            provider = get_provider(name)
            status = "configured" if provider.is_configured() else f"needs {provider.api_key_env}"
            model_source = "env" if os.environ.get(provider.model_env) else "config"
            print(f"  {provider.name:12} ({status})")
            print(f"               Model: {provider.default_model} (from {model_source})")
            print(f"               Override: {provider.model_env}=<model-name>")
        print("")
        print(f"Config file: {_CONFIG_PATH}")
        print("Usage: --provider grok,gemini,chatgpt  or  --provider all")
        sys.exit(0)

    # Parse providers
    provider_names = parse_providers(args.provider)
    if not provider_names:
        print("Error: No provider specified. Use --provider grok, gemini, chatgpt, or 'all'", file=sys.stderr)
        sys.exit(1)

    # Determine content source and review type
    content = None
    content_source = None
    review_type = args.type
    file_warnings = []

    if args.files:
        content, file_warnings = format_multi_files(args.files)
        content_source = f"--files ({', '.join(args.files)})"
        review_type = "multi"
        # Print warnings about file issues
        for warning in file_warnings:
            print(f"Warning: {warning}", file=sys.stderr)
    elif args.file:
        content_source = f"--file ({args.file})"
        try:
            with open(args.file, "r", encoding="utf-8") as f:
                content = f.read()
        except FileNotFoundError:
            print(f"\nError: File not found: {args.file}", file=sys.stderr)
            print(f"Make sure the path is correct and the file exists.", file=sys.stderr)
            print(f"Current working directory: {os.getcwd()}", file=sys.stderr)
            sys.exit(1)
        except PermissionError:
            print(f"\nError: Permission denied reading: {args.file}", file=sys.stderr)
            sys.exit(1)
        review_type = "diff" if args.diff else args.type
    elif args.content is not None:
        content = args.content
        content_source = "positional argument"
        review_type = "summary" if args.summary else ("diff" if args.diff else args.type)
    elif args.proposal:
        # Use proposal as content for plan/architecture reviews without code files
        # Check this BEFORE stdin because Claude Code may have stdin attached but empty
        content = args.proposal
        content_source = "--proposal"
        args.proposal = None  # Clear to avoid duplication in message
    elif not sys.stdin.isatty():
        content = sys.stdin.read()
        content_source = "stdin"
        review_type = "diff" if args.diff else args.type
    else:
        print_content_error(args)
        sys.exit(1)

    # Check if content is empty after stripping
    if not content or not content.strip():
        print_content_error(args, content_source)
        sys.exit(1)

    # Additional warning if all files were empty/unreadable
    if args.files and file_warnings and not content.strip():
        print("\nError: All specified files were empty or unreadable.", file=sys.stderr)
        sys.exit(1)

    # Build messages
    user_message = build_user_message(
        app_context=args.app_context,
        problem_context=args.context,
        proposal=args.proposal,
        already_considered=args.considered,
        content=content,
        review_type=review_type
    )

    # Token estimate
    est_tokens = estimate_tokens(user_message)
    if est_tokens > 500_000:
        print(f"Warning: ~{est_tokens:,} estimated tokens. Consider summarizing.", file=sys.stderr)

    # Build system prompt (template - provider name inserted later)
    system_prompt = build_system_prompt("{provider_name}", review_type)

    # Debug mode
    if args.debug:
        print("=" * 60, file=sys.stderr)
        print("DEBUG: INPUT SUMMARY", file=sys.stderr)
        print("=" * 60, file=sys.stderr)
        print(f"Providers: {', '.join(provider_names)}", file=sys.stderr)
        print(f"Review type: {review_type}", file=sys.stderr)
        print(f"Content source: {content_source}", file=sys.stderr)
        print(f"Content length: {len(content)} chars (~{est_tokens} tokens)", file=sys.stderr)
        print(f"App context: {args.app_context or '(not provided)'}", file=sys.stderr)
        print(f"Problem context: {args.context or '(not provided)'}", file=sys.stderr)
        print(f"Proposal: {args.proposal[:100] + '...' if args.proposal and len(args.proposal) > 100 else args.proposal or '(not provided)'}", file=sys.stderr)
        print(f"Already considered: {args.considered or '(not provided)'}", file=sys.stderr)
        if file_warnings:
            print(f"File warnings: {file_warnings}", file=sys.stderr)
        print("=" * 60, file=sys.stderr)
        print("SYSTEM PROMPT TEMPLATE:", file=sys.stderr)
        print(system_prompt, file=sys.stderr)
        print("=" * 60, file=sys.stderr)
        print("USER MESSAGE:", file=sys.stderr)
        print(user_message, file=sys.stderr)
        print("=" * 60, file=sys.stderr)

    # Call providers
    results: list[ProviderResult] = []

    if args.sequential or len(provider_names) == 1:
        # Sequential execution
        for name in provider_names:
            result = call_provider(name, system_prompt, user_message, args.model)
            results.append(result)
    else:
        # Parallel execution
        with concurrent.futures.ThreadPoolExecutor(max_workers=len(provider_names)) as executor:
            futures = {
                executor.submit(call_provider, name, system_prompt, user_message, args.model): name
                for name in provider_names
            }
            for future in concurrent.futures.as_completed(futures):
                results.append(future.result())

    # Output results
    if args.json:
        output = {
            "providers": [r.provider_name for r in results],
            "results": [
                {
                    "provider": r.provider_name,
                    "success": r.success,
                    "response": r.response if r.success else None,
                    "error": r.error if not r.success else None,
                    "model": r.model,
                    "usage": r.usage
                }
                for r in results
            ]
        }
        print(json.dumps(output, indent=2))
    elif len(results) == 1:
        print(format_result(results[0], review_type))
    else:
        print(format_multi_results(results, review_type))


if __name__ == "__main__":
    main()
