"""Grok (xAI) provider implementation."""

import json
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

from .base import AIProvider, ProviderResult, SSL_CONTEXT


class GrokProvider(AIProvider):
    """Provider for xAI's Grok models."""

    API_URL = "https://api.x.ai/v1/chat/completions"

    @property
    def name(self) -> str:
        return "Grok"

    @property
    def provider_key(self) -> str:
        return "grok"

    @property
    def api_key_env(self) -> str:
        return "XAI_API_KEY"

    @property
    def fallback_model(self) -> str:
        return "grok-4-1-fast-reasoning"

    @property
    def model_env(self) -> str:
        return "GROK_MODEL"

    def call_api(
        self,
        system_prompt: str,
        user_message: str,
        model: str | None = None
    ) -> ProviderResult:
        """Call the Grok API."""
        api_key = self.get_api_key()
        if not api_key:
            return ProviderResult(
                success=False,
                provider_name=self.name,
                error=f"{self.api_key_env} environment variable not set"
            )

        model = model or self.default_model
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ]

        payload = {
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 4096
        }

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            "User-Agent": "ai-pair-programmer/1.0"
        }

        try:
            req = Request(
                self.API_URL,
                data=json.dumps(payload).encode("utf-8"),
                headers=headers,
                method="POST"
            )
            with urlopen(req, timeout=120, context=SSL_CONTEXT) as response:
                result = json.loads(response.read().decode("utf-8"))
                return ProviderResult(
                    success=True,
                    provider_name=self.name,
                    response=result["choices"][0]["message"]["content"],
                    model=result.get("model", model),
                    usage=result.get("usage", {})
                )
        except HTTPError as e:
            error_body = e.read().decode("utf-8") if e.fp else str(e)
            return ProviderResult(
                success=False,
                provider_name=self.name,
                error=f"HTTP {e.code}: {error_body}"
            )
        except URLError as e:
            return ProviderResult(
                success=False,
                provider_name=self.name,
                error=f"Connection error: {e.reason}"
            )
        except Exception as e:
            return ProviderResult(
                success=False,
                provider_name=self.name,
                error=f"Unexpected error: {str(e)}"
            )
