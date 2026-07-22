---
name: standards-help
description: Explain the Trigent standards plugin — what standards exist, how they are applied during planning and implementation, and which skills to use. Use when asked how standards work, what the plugin does, or which libraries/conventions apply to a given stack. (Triggers - standards help, how do standards work, what is the standards plugin, coding conventions, which libraries)
---

# Trigent Standards

This plugin contains Trigent's organisational coding and architectural standards. These are reference files consumed by other skills — primarily `aidlc-design` (architectural guidance) and `aidlc-bolt` (implementation conventions for greenfield work).

## Available Standards

| File | Scope | Key Contents |
|------|-------|-------------|
| `global.md` | All projects | Security (OWASP), observability, API design, testing pyramid, resilience patterns |
| `dotnet.md` | .NET / C# | Project structure, CQRS/MediatR, preferred packages, testing framework (xUnit, NSubstitute) |
| `rails.md` | Ruby on Rails | Project structure, REST/GraphQL patterns, preferred gems, RSpec testing conventions |
| `iac.md` | Terraform + Terragrunt | Module structure, naming, state management, Azure targets |
| `application-profiles/` | .NET only | Trigent-specific patterns for each app type (Web API legacy/v10, Function App, Mixed Solution) |

## How Standards Are Applied

### During Planning (`/aidlc-design`)

`aidlc-design` loads `global.md` plus the project-type file (`dotnet.md`, `rails.md`, or `iac.md`) to inform architectural decisions — pattern selection, resilience requirements, API design. It does **not** load application profiles; those are implementation-level.

### During Implementation (`/aidlc-bolt`)

`aidlc-bolt` scans the existing codebase first. For **brownfield** work it matches whatever patterns are already in use (DI container, mocking library, mapping approach). For **greenfield** work it loads the appropriate project-type standards to inform implementation choices.

## Ownership

| File | Owner |
|------|-------|
| `global.md` | Architecture Guild |
| `dotnet.md` | .NET Chapter |
| `rails.md` | Ruby Chapter |
| `iac.md` | DevSecOps Chapter |
| `application-profiles/` | Architecture Guild |

Deviations from any standard require an ADR documenting the rationale.
