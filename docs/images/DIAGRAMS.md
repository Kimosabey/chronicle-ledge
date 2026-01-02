# 📝 Note on Diagrams

## Visual Strategy

This project uses a **dual approach** for technical documentation:

### 🎨 **Images** (Quick Understanding)
- **12 main concept diagrams** in `docs/images/`
- Professional PNG files for visual learners
- Used in README, SETUP guides, and doc headers
- **Purpose**: Fast comprehension for recruiters and presentations

### 📊 **Mermaid Diagrams** (Technical Detail)
- **25+ detailed flowcharts** embedded in technical docs
- Interactive, can be edited in Markdown  
- Used in HLD, LLD, and technical deep-dives
- **Purpose**: Precise technical specifications for developers

---

## Image Index

All 15 professional diagrams:

### System Overview
1. **architecture.png** - Complete system architecture
2. **complete-flows.png** - All 5 use case workflows
3. **data-journey.png** - Transaction lifecycle (~170ms)

### Patterns & Concepts
4. **event-sourcing-flow.png** - Event Sourcing vs CRUD
5. **cqrs-pattern.png** - Command/Query separation
6. **optimistic-locking.png** - Concurrency control (NEW!)
7. **snapshots.png** - Performance optimization (NEW!)
8. **saga-pattern.png** - Distributed transactions (NEW!)

### Features
9. **time-travel.png** - Time-travel queries
10. **api-reference.png** - All API endpoints
11. **dashboard.png** - UI mockup

### Reliability
12. **high-availability.png** - Node failure & recovery
13. **error-handling.png** - Error scenarios
14. **testing-strategy.png** - Testing workflows
15. **setup-guide.png** - 4-step setup

---

## Why Keep Both?

**Images**:
- ✅ Beautiful, professional
- ✅ Easy to share (presentations, PDFs)
- ✅ Fixed visual representation

**Mermaid**:
- ✅ Version-controlled (text-based)
- ✅ Can show detailed logic flows
- ✅ Easy to update (just edit markdown)
- ✅ GitHub renders automatically

---

**Best Practice**: Start with images for overview, dive into Mermaid for technical details.
