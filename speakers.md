---
layout: page
title: Speakers
permalink: /speakers/
---

<div class="list-of-people">
    <div class="person">
        <img src="/assets/img/speakers/lisa.jpeg" alt="Lisa Xiang Li">
        <a href="https://xiangli1999.github.io/" target="_blank">Lisa Xiang Li</a>
    </div>
    <div class="person">
        <img src="/assets/img/speakers/beidi.jpeg" alt="Beidi Chen">
        <a href="https://www.andrew.cmu.edu/user/beidic/" target="_blank">Beidi Chen</a>
    </div>
    <div class="person">
        <img src="/assets/img/speakers/samy.jpg" alt="Samy Bengio">
        <a href="https://bengio.abracadoudou.com/" target="_blank">Samy Bengio</a>
    </div>
    <div class="person">
        <img src="/assets/img/speakers/tom.jpg" alt="Tom Goldstein">
        <a href="https://www.cs.umd.edu/~tomg/" target="_blank">Tom Goldstein</a>
    </div>
    <div class="person">
        <img src="/assets/img/speakers/yuandong.png" alt="Yuandong Tian">
        <a href="https://yuandong-tian.com/" target="_blank">Yuandong Tian</a>
    </div>
    <div class="person">
        <img src="/assets/img/speakers/lingpeng.jpeg" alt="Lingpeng Kong">
        <a href="https://ikekonglp.github.io/" target="_blank">Lingpeng Kong</a>
    </div>
</div>

<script>
  var ul = document.querySelector('div.list-of-people');
  for (var i = ul.children.length; i >= 0; i--) {
      ul.appendChild(ul.children[Math.random() * i | 0]);
  }
</script>
