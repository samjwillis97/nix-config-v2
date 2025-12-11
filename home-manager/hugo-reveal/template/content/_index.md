+++
title = "Demo Presentation"
outputs = ["Reveal"]

[params.reveal_hugo]
custom_theme = "stylesheets/nib-theme.scss"
custom_theme_compile = true
+++

# Title Slide Heading

---

## First Slide Heading

Yep here we go

Hello docker

![docker](images/docker.svg)

---

## This is another slide

Now we are going to test inlien code blocks `another`

And a second line goes here

lets start hugo

```bash
hugo server --port 1314 --bind 127.0.0.1
```
---

## Code test slide

```json
{
    "this": "is",
    "a": true,
    "json": 1
}
```

---

## Mermaid test slide

```mermaid
flowchart LR
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]
```

---

## Mermaid with custom CSS

```mermaid
flowchart LR
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]
```

---


## Side by side 

{{< container_columns "100%" "left" "10px" >}}

{{% note %}}
Say thank you
{{% /note %}}

This should be in the first column:

- First point
- second point

----  <!-- Separator between columns -->

This should be in the second column:

```json
{
    "this": "is",
    "a": true,
    "json": 1
}
```

{{% note %}}
And thank the audience
{{% /note %}}

{{</ container_columns >}}
