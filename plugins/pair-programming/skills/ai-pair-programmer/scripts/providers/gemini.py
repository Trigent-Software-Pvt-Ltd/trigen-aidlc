"""Google Gemini provider implementation."""

import json
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

from .base import AIProvider, ProviderResult, SSL_CONTEXT


class GeminiProvider(AIProvider):
    """Provider for Google's Gemini models."""

    API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"

    @property
    def name(self) -> str:
        return "Gemini"

    @property
    def provider_key(self) -> str:
        return "gemini"

    @property
    def api_key_env(self) -> str:
        return "GEMINI_API_KEY"

    @property
    def fallback_model(self) -> str:
        return "gemini-2.0-flash"

    @property
    def model_env(self) -> str:
        return "GEMINI_MODEL"

    def call_api(
        self,
        system_prompt: str,
        user_message: str,
        model: str | None = None
    ) -> ProviderResult:
        """Call the Gemini API."""
        api_key = self.get_api_key()
        if not api_key:
            return ProviderResult(
                success=False,
                provider_name=self.name,
                error=f"{self.api_key_env} environment variable not set"
            )

        model = model or self.default_model
        url = f"{self.API_BASE}/{model}:generateContent?key={api_key}"

        # Gemini uses a different message format than OpenAI
        payload = {
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": user_message}]
                }
            ],
            "systemInstruction": {
                "parts": [{"text": system_prompt}]
            },
            "generationConfig": {
                "temperature": 0.7,
                "maxOutputTokens": 4096,
            }
        }

        headers = {
            "Content-Type": "application/json",
            "User-Agent": "ai-pair-programmer/1.0"
        }

        try:
            req = Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers=headers,
                method="POST"
            )
            with urlopen(req, timeout=120, context=SSL_CONTEXT) as response:
                result = json.loads(response.read().decode("utf-8"))

                # Extract response text from Gemini's format
                candidates = result.get("candidates", [])
                if not candidates:
                    return ProviderResult(
                        success=False,
                        provider_name=self.name,
                        error="No response candidates returned"
                    )

                content = candidates[0].get("content", {})
                parts = content.get("parts", [])
                if not parts:
                    return ProviderResult(
                        success=False,
                        provider_name=self.name,
                        error="Empty response from Gemini"
                    )

                response_text = parts[0].get("text", "")

                # Extract usage metadata
                usage_meta = result.get("usageMetadata", {})
                usage = {
                    "prompt_tokens": usage_meta.get("promptTokenCount", 0),
                    "completion_tokens": usage_meta.get("candidatesTokenCount", 0),
                    "total_tokens": usage_meta.get("totalTokenCount", 0)
                }

                return ProviderResult(
                    success=True,
                    provider_name=self.name,
                    response=response_text,
                    model=model,
                    usage=usage
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
