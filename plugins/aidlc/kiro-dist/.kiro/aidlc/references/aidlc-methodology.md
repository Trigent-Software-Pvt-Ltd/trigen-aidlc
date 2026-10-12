# AI-DLC Methodology Reference

This document captures the complete AI-Driven Development Lifecycle (AI-DLC) methodology, based on the AWS method definition by Raja SP.

## 1. Context

The evolution of software engineering has been a continuous quest to enable developers to focus on solving complex problems by abstracting away lower-level, undifferentiated tasks. From early machine code to high-level programming languages and the adoption of APIs and libraries, each step has significantly boosted developer productivity.

The integration of Large Language Models has revolutionized how software is created, introducing conversational natural language interactions for tasks like code generation, bug detection, and test generation. This marks the **AI-Assisted era**, where AI enhances specific, fine-grained tasks.

As AI evolves, its applications are expanding beyond code generation to include requirements elaboration, planning, task decomposition, design, and real-time collaboration with developers. This shift is kick-starting the **AI-Driven era**, where AI actively orchestrates the development process.

### Why Reimagine?

Existing software development methods, designed for human-driven, long-running processes, are not fully aligned with AI's speed, flexibility, and advanced capabilities. Their reliance on manual workflows and rigid role definitions limits the ability to fully leverage AI. Retrofitting AI into these methods not only limits its potential but also reinforces outdated inefficiencies.

**AI-DLC is an AI-native methodology designed to fully integrate the capabilities of AI, setting the foundations for the next evolution in software engineering.**

---

## 2. Key Principles

The following 10 principles form the foundation for AI-DLC, shaping its phases, roles, artifacts, and rituals.

### Principle 1: Reimagine Rather Than Retrofit

We choose to reimagine a development method rather than keeping existing methods like SDLC or Agile (e.g., Scrum) and retrofitting AI into them. Traditional methods were built for longer iteration durations (months and weeks), leading to rituals like daily standups and retrospectives. In contrast, proper application of AI leads to rapid cycles measured in **hours or days**.

- Would effort estimation (e.g., story points) be as critical if AI diminishes the boundaries between simple, medium, and hard tasks?
- Would metrics like velocity be relevant, or should we replace it with Business Value?

AI is evolving to automate manual practices including planning, task decomposition, requirements analysis, and application of design techniques. These dynamics warrant reimagination based on first principles thinking. **We need automobiles, not faster horse chariots.**

### Principle 2: Reverse the Conversation Direction

AI-DLC introduces a fundamental shift where **AI initiates and directs conversations with humans** instead of humans initiating conversations with AI to complete tasks. AI drives workflows by:

- Breaking down high-level features into actionable tasks
- Generating recommendations
- Proposing trade-offs

**Humans serve as approvers**, validating, selecting options, and confirming decisions at critical junctures. This allows developers to focus on high-value decision-making while AI handles planning, task decomposition, and automation.

**Analogy:** Google Maps - humans set the destination (the feature), and the system provides step-by-step directions (AI's task decomposition and recommendations). Along the way, humans maintain oversight and moderate the journey as needed.

### Principle 3: Integration of Design Techniques into the Core

Agile frameworks like Scrum or Kanban leave design techniques (e.g., Domain Driven Design) out of scope, recommending teams choose their own. This has left critical whitespaces that led to poor software quality. Software quality issues in the US alone were estimated to cost $2.41 Trillion in 2022.

Rather than decoupling design techniques, **AI-DLC integrates them as its core**. There are different flavors of AI-DLC:

- **DDD Flavor** - Uses Domain Driven Design principles
- **BDD Flavor** - Uses Behavior Driven Development
- **TDD Flavor** - Uses Test-Driven Development

This integration is key to enabling hourly or daily iteration cycles while eliminating manual heavy-lifting and maintaining software quality (the mantra of "**Build Better Systems Faster**").

### Principle 4: Align with AI Capability

AI-DLC recognizes that current AI is advancing but **not yet reliable in autonomously translating high-level intentions into executable code** or independently operating without human oversight, while ensuring interpretability and safety.

At the same time, the AI-Assisted paradigm (developers do the heavy lifting with AI providing augmentation) fails to unlock AI's full potential.

**AI-DLC adopts the AI-Driven paradigm**, which balances human involvement with the capabilities and limitations of current AI. Developers retain ultimate responsibility for:

- Validation
- Decision-making
- Oversight

### Principle 5: Cater to Building Complex Systems

AI-DLC caters to building systems that demand:

- Continuous functional adaptability
- High architectural complexity
- Numerous trade-off management
- Scalability
- Integration and customization requirements

These necessitate advanced design techniques, patterns, and best practices, typically involving multiple teams working cohesively within large and/or regulated organizations.

**Simpler systems** that can be developed by non-developer personas with few trade-off management needs are **outside the scope of AI-DLC** and are better suited for low-code/no-code approaches.

### Principle 6: Retain What Enhances Human Symbiosis

While reimagining the method, we retain artifacts and touchpoints from existing methods that are critical for:

- **Human validation** - User stories align humans' and AI's understanding of what needs to be built, acting as well-defined contracts
- **Risk mitigation** - Risk Register ensures AI-generated plans and code comply with organizational risk frameworks

These retained elements are optimized for real-time use, allowing rapid iterations without compromising alignment or safety.

### Principle 7: Facilitate Transition Through Familiarity

The new method shall not demand extensive training - any existing practitioner should be able to orient and start practicing it **in a single day**.

To support easier adoption via associative learning, AI-DLC preserves underlying relationships between familiar terms while introducing modernized terminology.

**Example:** Sprints in Scrum represent iterative cycles for building and validating. But Sprints are usually 4-6 weeks long. With AI-DLC, iteration cycles are continuous and measured in hours or days. Therefore, **AI-DLC redefines Sprints** as rapid, intense cycles measured in hours or days that deliver unprecedented velocity.

### Principle 8: Streamline Responsibilities for Efficiency

By leveraging AI's ability to perform task decomposition and decision-making, developers are empowered to **transcend traditional specialization silos** such as infrastructure, front-end, back-end, DevOps, and security. This convergence reduces the need for multiple specialized roles.

**Product Owners and developers remain integral**, retaining critical responsibilities for:

- Oversight
- Validation
- Strategic decision-making
- Alignment with business objectives
- Design quality
- Compliance with risk management frameworks

### Principle 9: Minimize Stages, Maximize Flow

Through automation and convergence of responsibilities, AI-DLC aims to minimize handoffs and transitions, enabling **continuous iterative flow**.

Human validation and decision-making remain critical to ensure AI-generated code does not become rigid ("quick-cement") but stays adaptable for future iterations. AI-DLC incorporates **minimal but sufficient phases** designed for human oversight at critical decision junctures.

These validations act as a **"loss function"** - identifying and pruning wasteful downstream efforts before they occur.

### Principle 10: No Hard-Wired, Opinionated SDLC Workflows

AI-DLC avoids prescribing opinionated workflows for different development pathways (new system development, refactoring, defect fixes, microservice scaling). Instead, it adopts a truly **AI-First approach** where AI recommends the Level 1 Plan based on the given pathway intention.

Humans verify and moderate these AI-generated plans through interactive dialogue, continuing through Level 2 (subtasks) and subsequent hierarchy levels. This flexible approach ensures the methodology is adaptable and can evolve alongside AI capabilities while maintaining human control over critical decisions.

---

## 3. Core Framework: Artifacts

### Feature

A **Feature** is a high-level statement of purpose that encapsulates what needs to be achieved - whether a business goal, a capability, or a technical outcome (e.g., performance scaling). It serves as the starting point for AI-driven decomposition into actionable tasks, aligning human objectives with AI-generated plans.

### Epic

An **Epic** represents a cohesive, self-contained work element derived from a Feature, designed to deliver measurable value.

**Analogy:** Epics are analogous to Subdomains in DDD or Epics in Scrum.

Each Epic encompasses:
- A set of Tasks that articulate its functional scope
- Loose coupling to other Epics, enabling autonomous development and independent deployment

The process of decomposing Features into Epics is driven by AI, with developers and/or Product Owners validating and refining the resulting Epics.

### Sprint

A **Sprint** is the smallest iteration in AI-DLC, designed for the rapid implementation of an Epic or a set of tasks within an Epic.

**Analogy:** Sprints in AI-DLC parallel Sprints in Scrum, but emphasize intense focus and high-velocity delivery, with build-validation cycles measured in **hours or days** rather than weeks.

Each Sprint:
- Encapsulates a well-defined scope of work (e.g., Tasks within an Epic)
- Enables incremental progress while maintaining alignment with Epic objectives
- An Epic can be executed through one or more Sprints, running in parallel or sequentially

### Domain Design

The **Domain Design** artifact models the core business logic of an Epic, independently of infrastructure components.

Using Domain-Driven Design principles, AI creates strategic and tactical modeling elements:
- Aggregates
- Value Objects
- Entities
- Domain Events
- Repositories
- Factories

### Logical Design

**Logical Design** translates Domain Designs by extending them for meeting non-functional requirements using appropriate architectural design patterns (e.g., CQRS, Circuit Breakers).

AI creates Architecture Decision Records (ADRs) for validation by developers. With the Logical Design specification, AI generates code and unit tests, ensuring adherence to well-architected principles.

### Deployment Units

**Deployment Units** are operational artifacts encompassing:
- Packaged executable code (container images, serverless functions)
- Configurations (Helm Charts)
- Infrastructure components (Terraform, CloudFormation stacks)

These units are rigorously tested for:
- Functional acceptance
- Security compliance
- Adherence to non-functional requirements (NFRs)
- Mitigation of operational risks

---

## 4. Phases and Rituals

### Inception Phase: Mob Elaboration

The Inception Phase focuses on capturing Features and translating them into Epics for development. It uses **Mob Elaboration**, a collaborative requirements elaboration and decomposition ritual.

**Setup:**
- Single room (physical or virtual) with shared screen
- Led by a facilitator
- Participants: Product Owner, Developers, QA, relevant stakeholders

**AI's Role:**
AI proposes an initial breakdown of the Feature into:
- Tasks
- Acceptance Criteria
- Epics
- Proposed Sprint groupings

Using domain knowledge and principles of **loose coupling and high cohesion** for rapid parallel execution.

**Human's Role:**
The mob collaboratively reviews and refines AI-generated artifacts by:
- Adjusting under-engineered or over-engineered parts
- Aligning them with real-world constraints

**Outputs:**
- Well-defined Epics containing:
  - PRFAQ (optional)
  - Tasks (following "As a... I want... So that..." format)
  - Non-Functional Requirements (NFRs)
  - Risk descriptions (matching organization's Risk Register)
  - Measurement Criteria (tracing to business feature)
  - Proposed Sprint groupings for construction

**Value:** Mob Elaboration condenses weeks or months of sequential work into **a few hours**, achieving deep alignment both within the mob and between the mob and the AI.

### Construction Phase: Mob Programming

The Construction Phase encompasses the iterative execution of tasks, transforming Epics into tested, operations-ready Deployment Units.

**Progression:**
1. **Domain Design** - AI models business logic independently of technical considerations
2. **Logical Design** - Non-functional requirements and cloud design patterns are applied
3. **Code Generation** - AI generates code mapping components to services while adhering to well-architected principles
4. **Testing** - Automated testing ensures functionality, security, and operational readiness

**Mob Programming Ritual:**
- All teams collocated in a single room (like Mob Elaboration)
- Teams exchange integration specifications from domain model stage
- Make decisions and deliver their sprints

**Brown-field Specific:**
For existing applications, the construction phase first involves **elevating the code** into a semantic-rich modeling representation:
- Static models (components, responsibilities, relationships)
- Dynamic models (how components interact to realize significant use cases)

### Operations Phase

The Operations Phase centers on deployment, observability, and maintenance:

**Deployment:**
- AI packages modules into Deployment Units
- Developers approve configuration and initiate rollout

**Observability and Monitoring:**
- AI analyzes telemetry data (metrics, logs, traces)
- Detects patterns and identifies anomalies
- Predicts potential SLA violations
- Integrates with predefined incident runbooks
- Proposes actionable recommendations (scaling, tuning, fault isolation)

**Human's Role:**
Developers serve as validators, ensuring AI-generated insights and proposed actions align with SLAs and compliance requirements.

---

## 5. The Workflow (9 Steps)

Given a business feature (green-field, brown-field, modernization, or defect fixing), AI-DLC proceeds through these steps:

| Step | Description |
|------|-------------|
| **1** | Build context from existing code |
| **2** | Elaborate feature into Tasks and Epics |
| **3** | Group Tasks into Sprints |
| **4** | Model the domain, code & test builds |
| **5** | Solve the non-functional requirements |
| **6** | Resolve deployment architecture, code & test |
| **7** | Deploy to production |
| **8** | Monitor, handle |
| **9** | (Iteration continues) |

**Key Principle:** At the heart of AI-DLC is applying human oversight to progressively enrich artifacts at each step, transforming them into semantically rich context for the next. Each step serves as a **strategic decision point** where human oversight functions like a loss function - catching and correcting errors early before they snowball downstream.

**Context Memory:** All artifacts generated (Features, Tasks, domain models, test plans) are persisted and serve as a "context memory" that AI references across the lifecycle. All artifacts are linked for backward and forward traceability.

---

## 6. Green-field vs Brown-field

### Green-field Development

New application development following the full workflow:
1. Product Owner articulates high-level feature
2. AI recognizes feature as new application build
3. AI produces Level 1 plan
4. Team validates and refines the plan
5. Progress through Inception → Construction → Operations

### Brown-field Development

Changes to existing systems (new features, NFR optimization, technical debt, refactoring, defect fixes):

**Inception Phase:** Same as green-field

**Construction Phase (additional steps):**
1. AI elevates code into higher-level modeling representation
   - Static models (components, descriptions, responsibilities, relationships)
   - Dynamic models (how components interact for significant use cases)
2. Developers collaborate to review, validate, and correct the reverse-engineered models
3. Rest of construction phase proceeds like green-field

**Operations Phase:** Same as green-field

---

## 7. Example Prompts

The following prompts can be used to interact with AI for practicing AI-DLC.

### Setup Prompt

```
We will work on building an application today. For every front end and backend
component we will create a project folder. All documents will reside in the
aidlc-docs folder. Throughout our session I'll ask you to plan your work ahead
and create an md file for the plan. You may work only after I approve said plan.

These plans will always be stored in aidlc-docs/plans folder. You will create
many types of documents in the md format:
- Requirement/feature changes documents → aidlc-docs/requirements folder
- User stories → aidlc-docs/story-artifacts folder
- Architecture and Design documents → aidlc-docs/design-artifacts folder
- All prompts in order → aidlc-docs/prompts.md file

Confirm your understanding of this prompt. Create the necessary folders and
files for storage, if they do not exist already.
```

### Inception: Tasks

```
Your Role: You are an expert product manager tasked with creating well-defined
Tasks that become the contract for developing the system.

Plan for the work ahead and write your steps in an md file (tasks_plan.md)
with checkboxes for each step. If any step needs my clarification, add a note
to get my confirmation. Do not make critical decisions on your own.

Upon completing the plan, ask for my review and approval. After approval,
execute the plan one step at a time. Mark checkboxes as done when complete.

Your Task: Build Tasks for the high-level requirement: <<describe product>>
```

### Inception: Epics

```
Your Role: You are an experienced software architect.

Before starting, do the planning and write steps in units_plan.md with checkboxes.
If any step needs clarification, add it to interact with me. Do not make critical
decisions on your own.

Your Task: Refer to the Tasks in mvp_tasks.md file. Group the Tasks into
multiple epics that can be built independently. Each epic contains highly
cohesive Tasks that can be built by a single team. The epics are loosely
coupled with each other.

For each epic, write their respective Tasks and acceptance criteria in
individual md files in the design/ folder.
```

### Construction: Domain Model

```
Your Role: You are an experienced software engineer.

Before starting, write planning steps in design/component_model.md with checkboxes.

Your Task: Refer to the Tasks in design/<epic_name>_epic.md. Design the
component model to implement all Tasks. This model shall contain all
components, attributes, behaviors, and how components interact.

Do not generate any code yet. Write the component model into a separate md file
in the /design folder.
```

### Construction: Code Generation

```
Your Role: You are an experienced software engineer.

Task: Refer to component design in the <component>.md file. Generate a simple
and intuitive implementation for the component. Generate the classes in
respective individual files.
```

### Construction: Architecture

```
Your Role: You are an experienced Cloud Architect.

Before starting, write planning steps in deployment_plan.md with checkboxes.

Task: Refer to:
- Component design model: design/core_component_model.md
- Epics in the epics/ folder
- Cloud architecture in the ARCHITECTURE/ folder
- Backend code in the BACKEND/ folder

Complete the following:
- Generate end-to-end deployment plan using [CloudFormation, CDK, Terraform]
- Document all prerequisites
- Follow best practice of clean, simple, explainable coding
- All output code goes in the DEPLOYMENT/ folder
- Create validation plan and generate validation report
- Fix all identified issues and update validation report
```

---

## 8. Adoption Strategies

AI-DLC is designed with easier adoption as a key outcome. Two approaches facilitate adoption:

### Learning by Practicing

AI-DLC is a set of rituals (Mob Elaboration, Mob Construction) that can be practiced as a group. Instead of learning via documentation and traditional training, practitioners practice the rituals with AI-DLC guides in multiple real-world scenarios they are currently solving.

### Embedding in Developer Experience Tooling

Organizations are building orchestration tools that cut across SDLC, providing unified developer experience. By embedding AI-DLC in these tools, developers seamlessly practice AI-DLC without significant adoption drives.

---

## Summary Table: AI-DLC vs Traditional Methods

| Aspect | Traditional (Scrum) | AI-DLC |
|--------|---------------------|--------|
| **Iteration Cycle** | Sprints (2-6 weeks) | Sprints (hours to days) |
| **Conversation Direction** | Human initiates | AI initiates, human approves |
| **Design Techniques** | External/optional | Integrated core |
| **Effort Estimation** | Story points, velocity | Business value |
| **Work Grouping** | Epics | Epics (loosely coupled) |
| **Roles** | Specialized silos | Converged responsibilities |
| **Planning** | Human-driven | AI-driven with human oversight |
| **Rituals** | Daily standups, retrospectives | Mob Elaboration, Mob Programming |
