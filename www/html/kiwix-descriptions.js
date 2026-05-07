/* Quick Cat Library — description overrides */
(function () {
  const overrides = {
    "Wikipedia in simple English": {
      summary: "The whole of Wikipedia, no frills. Clear writing, real sources, works offline. Start here for anything.",
      title: "Wikipedia"
    },
    "Explain XKCD": {
      summary: "Every XKCD explained — the maths, the jokes, the references you almost got. Pairs well with the comic itself."
    },
    "xkcd": {
      summary: "Randall Munroe's entire run. Nerd comics about physics, relationships, and the internet. Fully offline."
    },
    "Permacomputing": {
      summary: "A wiki for computing that lasts. Low-power systems, repair culture, software that runs on less. Quietly radical."
    },
    "Appropedia": {
      summary: "30,000+ articles on sustainable tech — composting, water systems, solar, permaculture. Practical and deep."
    },
    "DevHints - Rico's cheatsheets": {
      summary: "Fast cheat sheets for bash, git, vim, docker, and more. The tab you always have open, now offline.",
      title: "DevHints"
    },
    "100 Rabbits": {
      summary: "Two people sailing and building from scratch. Off-grid computing, minimal tools, honest docs of what works."
    },
    "Solar Powered LowTech Magazine": {
      summary: "Long reads on low-tech alternatives — pedal power, wood gas, hand pumps. Solar-powered website, fittingly.",
      title: "Low-Tech Magazine"
    },
    "iFixit in English": {
      summary: "Step-by-step repair guides for phones, laptops, appliances. 100k+ guides. Fix it yourself, offline.",
      title: "iFixit"
    },
    "GrimGrains Recipes": {
      summary: "Plant-based recipes from the 100 Rabbits crew. Illustrated, whole ingredients, good food energy.",
      title: "GrimGrains"
    },
    "based.cooking LukeSmith": {
      summary: "No-nonsense recipes, no ads, no blog preamble. Just ingredients and method.",
      title: "Based Cooking"
    },
    "Incognito cat": {
      summary: "Practical privacy and security without the paranoia. VPNs, browsers, threat models — clear and actionable.",
      title: "Incognito Cat"
    },
    "Nicky Case": {
      summary: "Interactive essays on trust, systems thinking, and game theory. You play through the ideas."
    }
  };

  const origFetch = window.fetch;
  window.fetch = function (input, init) {
    return origFetch(input, init).then(function (response) {
      const url = typeof input === "string" ? input : input.url || "";
      if (!url.includes("/catalog/")) return response;

      const contentType = response.headers.get("content-type") || "";
      if (!contentType.includes("atom") && !contentType.includes("xml")) return response;

      return response.text().then(function (text) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(text, "application/xml");
        const entries = doc.querySelectorAll("entry");

        entries.forEach(function (entry) {
          const titleEl = entry.querySelector("title");
          if (!titleEl) return;
          const key = titleEl.textContent.trim();
          const ov = overrides[key];
          if (!ov) return;

          if (ov.summary) {
            let summaryEl = entry.querySelector("summary");
            if (!summaryEl) {
              summaryEl = doc.createElementNS("http://www.w3.org/2005/Atom", "summary");
              entry.appendChild(summaryEl);
            }
            summaryEl.textContent = ov.summary;
          }

          if (ov.title) {
            titleEl.textContent = ov.title;
          }
        });

        const serializer = new XMLSerializer();
        const modified = serializer.serializeToString(doc);
        return new Response(modified, {
          status: response.status,
          statusText: response.statusText,
          headers: response.headers
        });
      });
    });
  };
})();
