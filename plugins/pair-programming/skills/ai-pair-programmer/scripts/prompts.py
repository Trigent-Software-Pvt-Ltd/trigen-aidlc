"""Shared prompts and review type configurations for AI pair programming."""

# Template for the base system prompt - {provider_name} will be substituted
PAIR_PROGRAMMER_SYSTEM_TEMPLATE = """You are {provider_name}, acting as a pair programmer with Claude (another AI).

Claude is the lead architect on this task. They've analyzed the user's request, formulated a solution, and are asking for your second opinion before implementation.

Your role:
- Evaluate Claude's proposed solution critically but constructively
- Consider whether the approach fits the app's tech stack and patterns
- Suggest alternatives only if you see meaningful issues
- Be direct - Claude values honest feedback over politeness
- Remember: Claude makes the final decision, but your input matters
- If Claude mentions approaches already tried or rejected, don't suggest those again

Respond with:
1. ASSESSMENT: Is Claude's approach sound? Would you do the same?
2. CONCERNS: Any issues, edge cases, or risks Claude may have missed
3. ALTERNATIVES: Only if you'd do something meaningfully different (explain why)
4. VERDICT: "Agree with approach" / "Suggest adjustments" / "Recommend reconsidering"

Keep it concise. Claude will synthesize your feedback with their own judgment."""


REVIEW_TYPE_ADDONS = {
    "plan": """
Focus on the implementation plan:
- Are the steps logical and complete?
- Is the ordering correct?
- Are there missing considerations?""",

    "code": """
Focus on the code:
- Are there bugs, security issues, or logic errors?
- Does it follow the app's patterns and best practices?
- Performance or maintainability concerns?
Reference specific lines when relevant.""",

    "architecture": """
Focus on the architecture decision:
- Are the trade-offs well understood?
- How will this scale?
- Does it fit the existing system architecture?""",

    "general": """
Provide general feedback on Claude's approach.""",

    "summary": """
This is a high-level summary. Keep feedback high-level too.
Don't ask for code details - focus on direction and strategy.""",

    "diff": """
Focus on the changes in the diff:
- Issues introduced by these specific changes
- Side effects on other parts of the system
- Whether the changes achieve the stated goal""",

    "multi": """
These files are related and should be reviewed as a cohesive unit:
- Do they work well together?
- Are there inconsistencies across files?
- Cross-file dependencies handled correctly?"""
}


# Language mapping for code block formatting
LANG_MAP = {
    ".py": "python",
    ".js": "javascript",
    ".ts": "typescript",
    ".tsx": "typescript",
    ".jsx": "javascript",
    ".java": "java",
    ".cs": "csharp",
    ".swift": "swift",
    ".kt": "kotlin",
    ".go": "go",
    ".rs": "rust",
    ".rb": "ruby",
    ".php": "php",
    ".xml": "xml",
    ".xaml": "xml",
    ".json": "json",
    ".yaml": "yaml",
    ".yml": "yaml",
    ".md": "markdown",
    ".sql": "sql",
    ".sh": "bash",
    ".bash": "bash",
    ".html": "html",
    ".css": "css",
    ".scss": "scss",
}


def build_system_prompt(provider_name: str, review_type: str) -> str:
    """Build the system prompt with provider name and type-specific additions."""
    base = PAIR_PROGRAMMER_SYSTEM_TEMPLATE.format(provider_name=provider_name)
    addon = REVIEW_TYPE_ADDONS.get(review_type, REVIEW_TYPE_ADDONS["general"])
    return base + "\n" + addon


def build_user_message(
    app_context: str | None,
    problem_context: str | None,
    proposal: str | None,
    already_considered: str | None,
    content: str,
    review_type: str
) -> str:
    """Build a structured message with all context."""
    sections = []

    if app_context:
        sections.append(f"## App Context\n{app_context}")

    if problem_context:
        sections.append(f"## Problem / User Request\n{problem_context}")

    if proposal:
        sections.append(f"## Claude's Proposed Solution\n{proposal}")

    if already_considered:
        sections.append(f"## Already Considered / Rejected\n{already_considered}")

    # Add the main content with appropriate header
    content_headers = {
        "plan": "## Implementation Plan",
        "code": "## Code to Review",
        "architecture": "## Architecture Decision",
        "diff": "## Changes (Diff)",
        "multi": "## Files to Review",
        "summary": "## Summary",
        "general": "## Content for Review"
    }
    header = content_headers.get(review_type, "## Content for Review")
    sections.append(f"{header}\n{content}")

    return "\n\n".join(sections)
