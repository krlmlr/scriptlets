// @ts-check

// Finicky 4 reads this file as an ECMAScript module, and hands every callback
// a standard URL instance rather than the objects Finicky 3 had of its own:
// https://github.com/johnste/finicky/wiki/Configuration-(v4)

/**
 * @typedef {import('/Applications/Finicky.app/Contents/Resources/finicky.d.ts').FinickyConfig} FinickyConfig
 */

/** @type {FinickyConfig} */
export default {
  // Possible options: ["Google Chrome", "Safari", "Firefox", ...]
  defaultBrowser: "Firefox",
  handlers: [
    {
      match: "http://*.orb.local*",
      browser: "Safari"
    },
    {
      match: ["http://support.posit.co/*", "https://support.posit.co/*"],
      browser: "Safari"
    },
    {
      // A URL instance keeps the colon in the scheme
      match: (url) => url.protocol === "clickup:",
      browser: "ClickUp"
    },
    {
      match: /zoom\.us\/j\//,
      browser: "us.zoom.xos"
    },
  ],
  rewrite: [
    {
      // The click tracker ClickUp's notification mails wrap their links in:
      // https://link-inbox.clickup.com/CL0/https:%2F%2Fapp.clickup.com%2Ft%2F86c1au25p%3Fcomment=90150095296062%26threadedComment=90150095416601%26utm_source=email-notifications%26utm_type=2%26utm_field=comment/1/010001943ba132c9-6ba4ceb3-9da1-4771-8022-60d330932eb7-000000/U4wqDVk2GS865NI30mhkcQc0HqXDzSuXR5-V2AnWBDg=386
      match: "https://link-inbox.clickup.com/CL0/*",
      url: (url) => {
        // URL unescape, remove header, remove CL0, remove https://
        const target = url.pathname
          .slice(1)
          .replaceAll("%2F", "/")
          .replaceAll("%3F", "?")
          .replaceAll("%26", "&")
          .replace("CL0/https://", "");

        return `clickup://${target}${url.search}${url.hash}`;
      }
    },
    {
      match: "https://app.clickup.com/*",
      url: (url) => `clickup://${url.pathname.slice(1)}${url.search}${url.hash}`
    },
  ],
};
