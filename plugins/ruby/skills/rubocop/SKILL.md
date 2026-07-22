---
name: rubocop
description: "Run rubocop on the specified file and fix violations, adding disable comments only when the rule is incorrect or dangerous"
allowed-tools: [Bash, Read, Edit, MultiEdit]
argument-hint: "<file_path>"
---

Run rubocop on the specified file and iteratively fix all violations. Follow these guidelines:

1. Run `bundle exec rubocop -a $ARGUMENTS` to identify violations. You may omit the path to run on all files.
2. For each violation, do one of the following:
   - Fix the code to comply with the style rule
   - Correct the code to not confuse rubocop
   - Add `# rubocop:disable <CopName>` comments ONLY if the rule is incorrect or dangerous, with a clear explanation of why
3. Re-enable disabled rules immediately after the problematic lines using `# rubocop:enable <CopName>`
4. Continue running rubocop until all violations are resolved or properly disabled
5. Show the final clean rubocop output

Always prefer fixing the code over disabling rules. Only disable rules when:
- The rule would make the code less readable or maintainable
- The rule conflicts with established project patterns
- Following the rule would introduce bugs or security issues
- The rule is contextually inappropriate for the specific code

Provide clear, specific reasons for any disabled rules.
