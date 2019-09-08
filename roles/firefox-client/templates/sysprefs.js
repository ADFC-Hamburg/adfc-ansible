// ADFC Settings, bitte im ADFC-Ansible Git bearbeiten
//
// pref(prefName, value) – bestimmt den Benutzerwert einer Einstellung. Diese Funktion legt die Präferenz explizit als Benutzerpräferenz fest. Das heißt, wenn der Benutzer den Wert geändert hat, wird er bei jedem Browserstart zurückgesetzt.
//
// pref(prefName, value) – bestimmt den Standardwert einer Voreinstellung. Dies ist der Wert, den eine Einstellung hat, wenn der Benutzer keinen Wert festgelegt hat.
//
// lockPref(prefName, value) – bestimmt den Standardwert einer Voreinstellung und sperrt ihn. Diese Funktion ist den meisten Anwendern bekannt, wenn es um AutoConfig-Dateien geht. Durch das Sperren einer Voreinstellung wird verhindert, dass ein Benutzer diese ändert, und in den meisten Fällen wird die Benutzeroberfläche in den Voreinstellungen deaktiviert, sodass für den Benutzer offensichtlich ist, dass die Voreinstellung deaktiviert wurde.

pref("browser.startup.homepage","https://hamburg.adfc.de/");


// Inhalt von https://www.privacy-handbuch.de/download/minimal/user.js
// https://www.privacy-handbuch.de/handbuch_21u.htm

pref("app.normandy.enabled", false);
pref("app.normandy.api_url", "");
pref("app.shield.optoutstudies.enabled", false);
pref("browser.aboutHomeSnippets.updateUrl", "");
pref("browser.cache.compression_level", 1);
pref("browser.cache.disk.enable", false);
pref("browser.cache.disk_cache_ssl", false);
pref("browser.cache.offline.enable", false);
pref("browser.fixup.alternate.enabled", false);
pref("browser.library.activity-stream.enabled", false);
pref("browser.newtabpage.activity-stream.enabled", false);
pref("browser.newtabpage.enabled", false);
pref("browser.newtabpage.activity-stream.asrouterExperimentEnabled", false);
pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
pref("browser.newtabpage.activity-stream.telemetry", false);
pref("browser.newtabpage.activity-stream.feeds.sections", false);
pref("browser.newtabpage.activity-stream.feeds.snippets", false);
pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
pref("browser.newtabpage.activity-stream.feeds.systemtick", false);
pref("browser.newtabpage.activity-stream.feeds.topsites", false);
pref("browser.newtabpage.activity-stream.feeds.section.topstories.options", "");
pref("browser.newtabpage.activity-stream.telemetry.ping.endpoint", "");
pref("browser.onboarding.enabled", false);
pref("browser.pagethumbnails.capturing_disabled", true);
pref("browser.ping-centre.telemetry", false);
pref("browser.ping-centre.production.endpoint", "");
pref("browser.ping-centre.staging.endpoint", "");
pref("browser.safebrowsing.downloads.remote.url", " ");
pref("browser.safebrowsing.downloads.enabled", false);
pref("browser.safebrowsing.phishing.enabled", false);
pref("browser.safebrowsing.malware.enabled", false);
pref("browser.safebrowsing.downloads.remote.enabled", false);
pref("browser.safebrowsing.downloads.remote.block_dangerous", false);
pref("browser.safebrowsing.downloads.remote.block_dangerous_host", false);
pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
pref("browser.safebrowsing.blockedURIs.enabled", false);
pref("browser.safebrowsing.provider.google.gethashURL", "");
pref("browser.safebrowsing.provider.google.updateURL", "");
pref("browser.safebrowsing.provider.google4.gethashURL", "");
pref("browser.safebrowsing.provider.google4.updateURL", "");
pref("browser.safebrowsing.provider.mozilla.gethashURL", "");
pref("browser.safebrowsing.provider.mozilla.updateURL", "");
pref("browser.search.update", false);
pref("browser.search.countryCode", "DE");
pref("browser.search.geoSpecificDefaults", false);
pref("browser.search.geoSpecificDefaults.url", "");
pref("browser.search.geoip.url", "");
pref("browser.search.suggest.enabled", false);
pref("browser.search.reset.enabled", false);
pref("browser.search.reset.status", "");
pref("browser.search.reset.whitelist", "");
pref("browser.search.widget.inNavBar", true);
pref("browser.sessionstore.max_tabs_undo", 0);
pref("browser.sessionstore.max_windows_undo", 0);
pref("browser.sessionstore.privacy_level", 2);
pref("browser.slowStartup.notificationDisabled", true);
pref("browser.slowStartup.maxSamples", 0);
pref("browser.slowStartup.samples", 0);
pref("browser.startup.page", 0);
pref("browser.tabs.crashReporting.sendReport", false);
pref("browser.urlbar.trimURLs", false);
pref("browser.urlbar.oneOffSearches", false);
pref("browser.urlbar.suggest.openpage", false);
pref("browser.urlbar.suggest.searches", false);
pref("datareporting.healthreport.uploadEnabled", false);
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("experiments.activeExperiment", false);
pref("experiments.enabled", false);
pref("experiments.manifest.uri", "");
pref("experiments.supported", false);
pref("extensions.blocklist.enabled", false);
pref("extensions.blocklist.url", "");
pref("extensions.getAddons.cache.enabled", false);
pref("extensions.pocket.enabled", false);
pref("extensions.screenshots.upload-disabled", true);
pref("extensions.systemAddon.update.enabled", false);
pref("extensions.systemAddon.update.url", "");
pref("extensions.webextensions.restrictedDomains", "");
pref("media.cache_size", 0);
pref("network.allow-experiments", false);
pref("network.captive-portal-service.enabled", false);
pref("network.http.referer.XOriginPolicy", 2);
pref("network.IDN_show_punycode", true);
pref("places.history.enabled", false);
pref("network.manage-offline-status", false);
pref("privacy.clearOnShutdown.cache", true);
pref("privacy.clearOnShutdown.cookies", true);
pref("privacy.clearOnShutdown.downloads", true);
pref("privacy.clearOnShutdown.history", true);
pref("privacy.clearOnShutdown.offlineApps", true);
pref("privacy.clearOnShutdown.openWindows", false);
pref("privacy.clearOnShutdown.sessions", true);
pref("privacy.clearOnShutdown.formdata", true);
pref("privacy.clearOnShutdown.siteSettings", true);
pref("privacy.cpd.offlineApps", true);
pref("privacy.cpd.passwords", true);
pref("privacy.cpd.siteSettings", true);
pref("privacy.firstparty.isolate", true);
pref("privacy.history.custom", true);
pref("privacy.sanitize.sanitizeOnShutdown", true);
pref("privacy.userContext.enabled", true);
pref("privacy.userContext.ui.enabled", true);
pref("privacy.userContext.longPressBehavior", 2);
pref("privacy.usercontext.about_newtab_segregation.enabled", true);
pref("security.insecure_connection_icon.enabled", true);
pref("security.insecure_connection_icon.pbmode.enabled", true);
pref("security.insecure_connection_text.enabled", true);
pref("security.insecure_connection_text.pbmode.enabled", true);
pref("security.mixed_content.upgrade_display_content", true);
pref("security.family_safety.mode", 0);
pref("signon.autofillForms", false);
pref("signon.formlessCapture.enabled", false);
pref("shield.savant.enabled", false);
pref("startup.homepage_welcome_url", "");
pref("toolkit.coverage.endpoint.base", "");
pref("toolkit.coverage.opt-out", true);
pref("toolkit.telemetry.archive.enabled", false);
pref("toolkit.telemetry.coverage.opt-out", true);
pref("toolkit.telemetry.hybridContent.enabled", false);
pref("toolkit.telemetry.bhrPing.enabled", false);
pref("toolkit.telemetry.firstShutdownPing.enabled", false);
pref("toolkit.telemetry.newProfilePing.enabled", false);
pref("toolkit.telemetry.shutdownPingSender.enabled", false);
pref("toolkit.telemetry.updatePing.enabled", false);
pref("toolkit.telemetry.server", "");
pref("toolkit.telemetry.unified", false);
pref("toolkit.telemetry.infoURL", "");


// https://github.com/pyllyukko/user.js/


// Laut OTRS Ticket_

// Erweiterungen während des Surfens empfehlen: abschalten
// Datenschutz und Sicherheit: streng
// Do Not Track: Immer
// Zugangsdate und Passwörter: nicht speichern
// Berechtigungen für den Zugriff auf Standort, Kamera und Mikrofon abschalten
// Datenerhebung durch Firefox: deaktivieren
// folgende AddOns sollten möglichst installiert werden:
// uBlock Origin
// I don't care about cookies
// HTTPS Everywhere
