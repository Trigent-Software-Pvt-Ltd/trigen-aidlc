"""AI Provider implementations for pair programming reviews."""

from .base import AIProvider, ProviderResult
from .grok import GrokProvider
from .openai import OpenAIProvider
from .gemini import GeminiProvider

# Provider registry - maps names/aliases to provider classes
PROVIDER_REGISTRY = {
    # Grok / xAI
    "grok": GrokProvider,
    "xai": GrokProvider,

    # OpenAI / ChatGPT
    "openai": OpenAIProvider,
    "chatgpt": OpenAIProvider,
    "gpt": OpenAIProvider,

    # Google Gemini
    "gemini": GeminiProvider,
    "google": GeminiProvider,
}

def get_provider(name: str) -> AIProvider:
    """Get a provider instance by name."""
    name_lower = name.lower().strip()
    if name_lower not in PROVIDER_REGISTRY:
        available = ", ".join(sorted(set(PROVIDER_REGISTRY.keys())))
        raise ValueError(f"Unknown provider '{name}'. Available: {available}")
    return PROVIDER_REGISTRY[name_lower]()

def get_available_providers() -> list[str]:
    """Get list of unique provider names (canonical names only)."""
    seen = set()
    result = []
    for name, cls in PROVIDER_REGISTRY.items():
        if cls not in seen:
            seen.add(cls)
            result.append(name)
    return sorted(result)

def get_configured_providers() -> list[AIProvider]:
    """Get list of providers that have API keys configured."""
    configured = []
    seen_classes = set()
    for cls in PROVIDER_REGISTRY.values():
        if cls not in seen_classes:
            seen_classes.add(cls)
            provider = cls()
            if provider.is_configured():
                configured.append(provider)
    return configured

__all__ = [
    "AIProvider",
    "ProviderResult",
    "GrokProvider",
    "OpenAIProvider",
    "GeminiProvider",
    "PROVIDER_REGISTRY",
    "get_provider",
    "get_available_providers",
    "get_configured_providers",
]
