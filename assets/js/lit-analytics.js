(function () {
  "use strict";

  function track(name, parameters) {
    if (typeof window.gtag !== "function") return;
    window.gtag("event", name, parameters || {});
  }

  document.addEventListener("click", function (event) {
    var link = event.target.closest("a[href]");
    if (!link) return;

    var href = link.getAttribute("href") || "";
    var paper = link.closest("[data-paper-id]");

    if (paper && /^https?:/i.test(href)) {
      track("paper_open", {
        paper_id: paper.dataset.paperId,
        link_type: /github\.com|gitlab\.com|codeberg\.org/i.test(href) ? "code" : "paper"
      });
      return;
    }

    if (/\/data\/(papers\.json|papers\.csl\.json|reading-list\.md|ontology\.json|schema\.json|changes\.json|papers\.bib)(?:$|[?#])/i.test(href)) {
      track("data_download", { file_name: href.split("/").pop().split(/[?#]/)[0] });
      return;
    }

    if (/github\.com\/latent-implicit-thinking\/latent-implicit-thinking\.github\.io\/issues\/new/i.test(href)) {
      track("contribution_start", {
        contribution_type: /correction/i.test(href) ? "correction" : "paper"
      });
    }
  });
})();
