---
title: Home
layout: default
---

# {{ site.title }}

{{ site.description }}

---

{% assign sections = site.pages | group_by_exp: "page", "page.path | split: '/' | first" %}

{% for section in sections %}
  {% unless section.name == "" or section.name contains "." %}
- [{{ section.name | capitalize }}]({{ section.name }}/)
  {% endunless %}
{% endfor %}
