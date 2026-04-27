---
layout: page
title: Speakers
permalink: /speakers/
---

<div class="list-of-people">
    <div class="person">
        <a href="https://scholar.google.com/citations?user=hty-MWIAAAAJ&hl=zh-CN" target="_blank"><img src="/assets/img/speakers/Xingwei.jpeg" alt="Xingwei Qu"></a>
        <a href="https://scholar.google.com/citations?user=hty-MWIAAAAJ&hl=zh-CN" target="_blank">Xingwei Qu</a>
    </div>
    <div class="person">
        <a href="https://danfu.org/" target="_blank"><img src="/assets/img/speakers/DanFu.jpeg" alt="Dan Fu"></a>
        <a href="https://danfu.org/" target="_blank">Dan Fu</a>
    </div>
    <div class="person">
        <a href="https://bengio.abracadoudou.com/" target="_blank"><img src="/assets/img/speakers/samy.jpg" alt="Samy Bengio"></a>
        <a href="https://bengio.abracadoudou.com/" target="_blank">Samy Bengio</a>
    </div>
    <div class="person">
        <a href="https://www.cs.umd.edu/~tomg/" target="_blank"><img src="/assets/img/speakers/tom.jpg" alt="Tom Goldstein"></a>
        <a href="https://www.cs.umd.edu/~tomg/" target="_blank">Tom Goldstein</a>
    </div>
    <div class="person">
        <a href="https://yuandong-tian.com/" target="_blank"><img src="/assets/img/speakers/yuandong.png" alt="Yuandong Tian"></a>
        <a href="https://yuandong-tian.com/" target="_blank">Yuandong Tian</a>
    </div>
    <div class="person">
        <a href="https://ikekonglp.github.io/" target="_blank"><img src="/assets/img/speakers/lingpeng.jpeg" alt="Lingpeng Kong"></a>
        <a href="https://ikekonglp.github.io/" target="_blank">Lingpeng Kong</a>
    </div>
</div>

<script>
  var ul = document.querySelector('div.list-of-people');
  for (var i = ul.children.length; i >= 0; i--) {
      ul.appendChild(ul.children[Math.random() * i | 0]);
  }
</script>
