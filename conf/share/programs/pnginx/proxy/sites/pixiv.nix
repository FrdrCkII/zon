[
  {
    domain = "lc-event.pixiv.net";
    ips = [ "210.140.139.185" ];
    sni = "pixivision.net";
  }

  {
    domain = "pixiv.net";
    altNames = [
      "*.pixiv.net"
      "fanbox.cc"
      "*.fanbox.cc"
    ];
    ips = [
      "210.140.139.152"
      "210.140.139.155"
      "210.140.139.158"
      "210.140.139.161"
    ];
    sni = "pixivision.net";
  }

  {
    domain = "pixiv.pximg.net";
    ips = [
      "210.140.139.135"
      "210.140.139.132"
      "210.140.139.137"
      "210.140.139.134"
      "210.140.139.131"
      "210.140.139.133"
      "210.140.139.130"
      "210.140.139.129"
      "210.140.139.136"
    ];
    sni = "pixivision.net";
  }

  {
    domain = "i.pximg.net";
    altNames = [ "*.pximg.net" ];
    ips = [
      "210.140.139.135"
      "210.140.139.132"
      "210.140.139.137"
      "210.140.139.134"
      "210.140.139.131"
      "210.140.139.130"
      "210.140.139.129"
      "210.140.139.136"
    ];
    sni = "pixivision.net";
  }

  {
    domain = "a.pixiv.org";
    altNames = [ "*.pixiv.org" ];
    sni = "pixivision.net";
  }
]
