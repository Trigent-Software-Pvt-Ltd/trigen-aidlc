"""Base class for AI providers."""

from abc import ABC, abstractmethod
from dataclasses import dataclass
import json
import os
import ssl
from pathlib import Path

# Create SSL context - try certifi first, fall back to default
try:
    import certifi
    SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    SSL_CONTEXT = ssl.create_default_context()

# Load config from config.json
_CONFIG_PATH = Path(__file__).parent.parent.parent / "config.json"
_CONFIG = {}

def load_config() -> dict:
    """Load configuration from config.json."""
    global _CONFIG
    if not _CONFIG:
        try:
            with open(_CONFIG_PATH, "r", encoding="utf-8") as f:
                _CONFIG = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            _CONFIG = {"providers": {}, "defaults": {}}
    return _CONFIG

def get_provider_config(provider_key: str) -> dict:
    """Get config for a specific provider."""
    config = load_config()
    return config.get("providers", {}).get(provider_key, {})

def get_defaults() -> dict:
    """Get default settings."""
    config = load_config()
    return config.get("defaults", {})


@dataclass
class ProviderResult:
    """Result from an AI provider call."""
    success: bool
    provider_name: str
    response: str = ""
    error: str = ""
    model: str = ""
    usage: dict = None

    def __post_init__(self):
        if self.usage is None:
            self.usage = {}


class AIProvider(ABC):
    """Abstract base class for AI providers."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Human-readable name of the provider (e.g., 'Grok', 'OpenAI')."""
        pass

    @property
    @abstractmethod
    def provider_key(self) -> str:
        """Key used in config.json (e.g., 'grok', 'chatgpt', 'gemini')."""
        pass

    @property
    @abstractmethod
    def api_key_env(self) -> str:
        """Environment variable name for the API key."""
        pass

    @property
    @abstractmethod
    def fallback_model(self) -> str:
        """Fallback model if not specified in config."""
        pass

    @property
    @abstractmethod
    def model_env(self) -> str:
        """Environment variable name for model override (e.g., GROK_MODEL)."""
        pass

    @property
    def default_model(self) -> str:
        """Get the model with priority: env var > config > fallback."""
        # Check environment variable first
        env_model = os.environ.get(self.model_env)
        if env_model:
            return env_model
        # Then check config
        config = get_provider_config(self.provider_key)
        return config.get("model", self.fallback_model)

    def is_configured(self) -> bool:
        """Check if the provider has an API key configured (env var or config)."""
        return bool(self.get_api_key())

    def get_api_key(self) -> str | None:
        """Get the API key with priority: env var > config.json."""
        # Environment variable takes priority
        env_key = os.environ.get(self.api_key_env)
        if env_key:
            return env_key
        # Fall back to config.json
        config = get_provider_config(self.provider_key)
        return config.get("api_key")

    @abstractmethod
    def call_api(
        self,
        system_prompt: str,
        user_message: str,
        model: str | None = None
    ) -> ProviderResult:
        """
        Call the provider's API.

        Args:
            system_prompt: The system prompt setting context
            user_message: The user's message/content to review
            model: Optional model override

        Returns:
            ProviderResult with the response or error
        """
        pass

    def get_system_prompt_name(self) -> str:
        """
        Get the name to use in the system prompt for this provider.
        Override if the provider should be referred to differently.
        """
        return self.name
