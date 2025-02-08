module.exports = {
  // Possible options: ["Google Chrome", "Safari", "Firefox", ...]
  defaultBrowser: "Firefox",
  options: {
    // Hide the finicky icon from the top bar
    //hideIcon: true
  },
  handlers: [
    {
      match: "http://support.posit.co/*",
      browser: "Safari"
    },
    {
      match: "https://support.posit.co/*",
      browser: "Safari"
    },
    {
      match: ({ url }) => url.protocol === "clickup",
      browser: "ClickUp"
    },
    {
      match: /zoom\.us\/j\//,
      browser: "us.zoom.xos"
    },
  ],
  rewrite: [
    {
      match: "https://link-inbox.clickup.com/CL0/*",
      url: ({ url }) => ({
        ...url,
        protocol: "clickup",
        host: "",
        // https://link-inbox.clickup.com/CL0/https:%2F%2Fapp.clickup.com%2Ft%2F86c1au25p%3Fcomment=90150095296062%26threadedComment=90150095416601%26utm_source=email-notifications%26utm_type=2%26utm_field=comment/1/010001943ba132c9-6ba4ceb3-9da1-4771-8022-60d330932eb7-000000/U4wqDVk2GS865NI30mhkcQc0HqXDzSuXR5-V2AnWBDg=386
        // URL unescape, remove header, remove CL0, remove https://
        pathname: url.pathname.slice(1).replaceAll("%2F", "/").replaceAll("%3F", "?").replaceAll("%26", "&").replace("CL0/https://", "")
        // pathname: url.pathname.slice(1).replace("%2F", "/").replace("%2F", "/").replace("%2F", "/").replace("%2F", "/").replace("%2F", "/").replace("%2F", "/").replace("%3F", "?").replace("%26", "&").replace("%26", "&").replace("%26", "&").replace("%26", "&").replace("%26", "&").replace("%26", "&").replace("CL0/https://", "")
      })
    },
    {
      match: "https://app.clickup.com/*",
      url: ({ url }) => ({
        ...url,
        protocol: "clickup",
        host: "",
        pathname: url.pathname.slice(1)
      })
    },
  ],
};
