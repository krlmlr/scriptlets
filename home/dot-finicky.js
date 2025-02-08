module.exports = {
    // Possible options: ["Google Chrome", "Safari", "Firefox", ...]
    defaultBrowser: "Brave Browser",
    options: {
        // Hide the finicky icon from the top bar
        hideIcon: true
    },
    rewrite: [
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
    handlers: [
        {
            match: ({ url }) => url.protocol === "clickup",
            browser: "ClickUp"
        },
    ],
};
