# Human–Agent Collaboration Playbook

*Quick Reference for Mid-Sprint Decisions*

---

## 🎯 Core Lens

**AI outputs are proposals, not facts.** Our edge is not speed of generation but discernment, trust, and user experience.

---

## 🔄 Decision Trees

### If AI generates code…

**Human must:**

- ✅ Verify critical paths have tests (≥70% coverage of business-critical flows)
- ✅ Check UX alignment (does it make sense in the user journey?)
- ✅ Confirm maintainability (naming, docs, version control)

### If AI generates content/design…

**Human must:**

- ✅ Check clarity against target user profile
- ✅ Add provenance note (e.g., "This draft was AI-assisted, reviewed by [name]")
- ✅ Ensure alignment with tone, accessibility, and brand guidelines

### If deadline pressure threatens review…

**🟢 Safe corner cuts:**

- Reduce test breadth (cover only critical paths)
- Delay polish (styling, refactors)

**🔴 Unsafe cuts:**

- Skipping review of logic or UX impact
- Removing disclosure or provenance

---

## 🚨 Red Flag Checklist

*You may be drifting if:*

- 📈 Bugs or UX complaints rise faster than features ship
- ❓ No one can explain why a piece of code/content was accepted
- 📝 Documentation lags more than one sprint behind releases
- 🤔 Users or stakeholders express mistrust ("Did AI do this, or a human?")
- 📊 Team velocity looks high but actual adoption stalls

---

## 🆘 Emergency Protocols

*When principles conflict under pressure:*

1. **User safety > speed** → Never cut corners that put users at risk
2. **Trust > novelty** → If transparency slows us down, we slow down. Reputation loss costs more than missed deadlines
3. **Sustainability > spectacle** → A smaller release that endures beats a bigger one that crumbles

---

## 💪 Competitive Edge Reminder

- **Resilience beats speed**
- **Trust compounds**
- **Experience is sticky**

*This playbook is our operating advantage. In a saturated market, anyone can ship. Few can ship things worth keeping.*

---

**🔗 Links:**

- [Full Strategic Framework](./human-agent-strategic-collaboration.md)
- [Collaboration Rules](./collaboration-rules.md)
- [AI Collaboration Framework](./ai-collaboration-framework.md)

**📋 Usage:** Pin to sprint boards, embed in project wikis, reference during standups
