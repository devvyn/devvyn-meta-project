# Content Creation Coordination Template

**Domain**: Writing, video production, social media, podcasting

**Use Case**: Coordinate multi-agent content workflows from ideation through publication

---

## Agent Roles

### 1. **Strategy Agent**
- **Authority**: Content strategy, audience analysis, topic selection
- **Escalates to**: Human (Creator) for brand decisions

### 2. **Writer Agent**
- **Authority**: Content drafting, editing, SEO optimization
- **Escalates to**: Strategy for topic changes

### 3. **Production Agent**
- **Authority**: Video editing, audio mixing, graphics, formatting
- **Escalates to**: Human for creative direction

### 4. **Distribution Agent**
- **Authority**: Scheduling, cross-posting, platform optimization
- **Escalates to**: Strategy for distribution strategy changes

### 5. **Human (Creator)**
- **Authority**: Final creative approval, brand voice, monetization decisions

---

## Workflows

### Article Publication
```
Strategy: Identify trending topic
    ↓
Writer: Draft article
    ↓
Human: Review and approve
    ↓
Writer: SEO optimization
    ↓
Distribution: Schedule publication
    ↓
Distribution: Cross-post to social media
```

### Video Production
```
Strategy: Plan video concept
    ↓
Writer: Write script
    ↓
Human: Record footage
    ↓
Production: Edit video
    ↓
Writer: Write description/captions
    ↓
Human: Final approval
    ↓
Distribution: Publish and promote
```

### Content Series
```
Strategy: Plan 10-episode series
    ↓
Writer: Outline all episodes
    ↓
Human: Approve overall arc
    ↓
For each episode:
    Writer: Draft script
    Production: Create assets
    Distribution: Schedule release
```

---

## Configuration

```yaml
content_project:
  brand: "Your Brand Name"
  niche: "Tech/Education/Entertainment"
  platforms: ["youtube", "blog", "twitter", "tiktok"]
  schedule: "3x per week"

agents:
  strategy:
    authority_domains: ["topic_selection", "audience_analysis", "trends"]
    tools: ["google_trends", "youtube_analytics", "twitter_analytics"]

  writer:
    authority_domains: ["drafting", "editing", "seo"]
    tools: ["grammarly", "hemingway", "yoast_seo"]

  production:
    authority_domains: ["video_editing", "graphics", "audio"]
    tools: ["davinci_resolve", "premiere_pro", "audacity"]

  distribution:
    authority_domains: ["scheduling", "cross_posting", "engagement"]
    tools: ["buffer", "hootsuite", "later"]

quality_gates:
  content_quality:
    readability_score: "> 60"
    grammar_errors: "= 0"
    plagiarism_check: "< 5%"
    seo_score: "> 70"

  production_quality:
    video_resolution: ">= 1080p"
    audio_quality: "-16 LUFS"
    thumbnail_quality: "1280x720, high contrast"
```

---

## Success Metrics

- **Productivity**: 3x more content published
- **Quality**: 50% improvement in engagement rate
- **Consistency**: Zero missed publication deadlines
- **Growth**: 2x faster audience growth

---

**Version**: 1.0
**Last Updated**: 2025-10-30
