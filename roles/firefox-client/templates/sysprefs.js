// ADFC Settings, bitte im ADFC-Ansible Git bearbeiten
//
// pref(prefName, value) – bestimmt den Benutzerwert einer Einstellung. Diese Funktion legt die Präferenz explizit als Benutzerpräferenz fest. Das heißt, wenn der Benutzer den Wert geändert hat, wird er bei jedem Browserstart zurückgesetzt.
//
// defaultPref(prefName, value) – bestimmt den Standardwert einer Voreinstellung. Dies ist der Wert, den eine Einstellung hat, wenn der Benutzer keinen Wert festgelegt hat.
//
// lockPref(prefName, value) – bestimmt den Standardwert einer Voreinstellung und sperrt ihn. Diese Funktion ist den meisten Anwendern bekannt, wenn es um AutoConfig-Dateien geht. Durch das Sperren einer Voreinstellung wird verhindert, dass ein Benutzer diese ändert, und in den meisten Fällen wird die Benutzeroberfläche in den Voreinstellungen deaktiviert, sodass für den Benutzer offensichtlich ist, dass die Voreinstellung deaktiviert wurde.

defaultPref("browser.startup.homepage","https://hamburg.adfc.de/");


// Inhalt von https://www.privacy-handbuch.de/download/minimal/user.js
// https://www.privacy-handbuch.de/handbuch_21u.htm

defaultPref("app.normandy.enabled", false);
defaultPref("app.normandy.api_url", "");
defaultPref("app.shield.optoutstudies.enabled", false);
defaultPref("browser.aboutHomeSnippets.updateUrl", "");
defaultPref("browser.cache.compression_level", 1);
defaultPref("browser.cache.disk.enable", false);
defaultPref("browser.cache.disk_cache_ssl", false);
defaultPref("browser.cache.offline.enable", false);
defaultPref("browser.fixup.alternate.enabled", false);
defaultPref("browser.library.activity-stream.enabled", false);
defaultPref("browser.newtabpage.activity-stream.enabled", false);
defaultPref("browser.newtabpage.enabled", false);
defaultPref("browser.newtabpage.activity-stream.asrouterExperimentEnabled", false);
defaultPref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
defaultPref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
defaultPref("browser.newtabpage.activity-stream.telemetry", false);
defaultPref("browser.newtabpage.activity-stream.feeds.sections", false);
defaultPref("browser.newtabpage.activity-stream.feeds.snippets", false);
defaultPref("browser.newtabpage.activity-stream.feeds.telemetry", false);
defaultPref("browser.newtabpage.activity-stream.feeds.systemtick", false);
defaultPref("browser.newtabpage.activity-stream.feeds.topsites", false);
defaultPref("browser.newtabpage.activity-stream.feeds.section.topstories.options", "");
defaultPref("browser.newtabpage.activity-stream.telemetry.ping.endpoint", "");
defaultPref("browser.onboarding.enabled", false);
defaultPref("browser.pagethumbnails.capturing_disabled", true);
defaultPref("browser.ping-centre.telemetry", false);
defaultPref("browser.ping-centre.production.endpoint", "");
defaultPref("browser.ping-centre.staging.endpoint", "");
defaultPref("browser.safebrowsing.downloads.remote.url", " ");
defaultPref("browser.safebrowsing.downloads.enabled", false);
defaultPref("browser.safebrowsing.phishing.enabled", false);
defaultPref("browser.safebrowsing.malware.enabled", false);
defaultPref("browser.safebrowsing.downloads.remote.enabled", false);
defaultPref("browser.safebrowsing.downloads.remote.block_dangerous", false);
defaultPref("browser.safebrowsing.downloads.remote.block_dangerous_host", false);
defaultPref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
defaultPref("browser.safebrowsing.downloads.remote.block_uncommon", false);
defaultPref("browser.safebrowsing.blockedURIs.enabled", false);
defaultPref("browser.safebrowsing.provider.google.gethashURL", "");
defaultPref("browser.safebrowsing.provider.google.updateURL", "");
defaultPref("browser.safebrowsing.provider.google4.gethashURL", "");
defaultPref("browser.safebrowsing.provider.google4.updateURL", "");
defaultPref("browser.safebrowsing.provider.mozilla.gethashURL", "");
defaultPref("browser.safebrowsing.provider.mozilla.updateURL", "");
defaultPref("browser.search.update", false);
defaultPref("browser.search.countryCode", "DE");
defaultPref("browser.search.geoSpecificDefaults", false);
defaultPref("browser.search.geoSpecificDefaults.url", "");
defaultPref("browser.search.geoip.url", "");
defaultPref("browser.search.suggest.enabled", false);
defaultPref("browser.search.reset.enabled", false);
defaultPref("browser.search.reset.status", "");
defaultPref("browser.search.reset.whitelist", "");
defaultPref("browser.search.widget.inNavBar", true);
defaultPref("browser.sessionstore.max_tabs_undo", 0);
defaultPref("browser.sessionstore.max_windows_undo", 0);
defaultPref("browser.sessionstore.privacy_level", 2);
defaultPref("browser.slowStartup.notificationDisabled", true);
defaultPref("browser.slowStartup.maxSamples", 0);
defaultPref("browser.slowStartup.samples", 0);
defaultPref("browser.startup.page", 0);
defaultPref("browser.tabs.crashReporting.sendReport", false);
defaultPref("browser.urlbar.trimURLs", false);
defaultPref("browser.urlbar.oneOffSearches", false);
defaultPref("browser.urlbar.suggest.openpage", false);
defaultPref("browser.urlbar.suggest.searches", false);
defaultPref("datareporting.healthreport.uploadEnabled", false);
defaultPref("datareporting.policy.dataSubmissionEnabled", false);
defaultPref("experiments.activeExperiment", false);
defaultPref("experiments.enabled", false);
defaultPref("experiments.manifest.uri", "");
defaultPref("experiments.supported", false);
defaultPref("extensions.blocklist.enabled", false);
defaultPref("extensions.blocklist.url", "");
defaultPref("extensions.getAddons.cache.enabled", false);
defaultPref("extensions.pocket.enabled", false);
defaultPref("extensions.screenshots.upload-disabled", true);
defaultPref("extensions.systemAddon.update.enabled", false);
defaultPref("extensions.systemAddon.update.url", "");
defaultPref("extensions.webextensions.restrictedDomains", "");
defaultPref("media.cache_size", 0);
defaultPref("network.allow-experiments", false);
defaultPref("network.captive-portal-service.enabled", false);
defaultPref("network.http.referer.XOriginPolicy", 2);
defaultPref("network.IDN_show_punycode", true);
defaultPref("places.history.enabled", false);
defaultPref("network.manage-offline-status", false);
defaultPref("privacy.clearOnShutdown.cache", true);
defaultPref("privacy.clearOnShutdown.cookies", true);
defaultPref("privacy.clearOnShutdown.downloads", true);
defaultPref("privacy.clearOnShutdown.history", true);
defaultPref("privacy.clearOnShutdown.offlineApps", true);
defaultPref("privacy.clearOnShutdown.openWindows", false);
defaultPref("privacy.clearOnShutdown.sessions", true);
defaultPref("privacy.clearOnShutdown.formdata", true);
defaultPref("privacy.clearOnShutdown.siteSettings", true);
defaultPref("privacy.cpd.offlineApps", true);
defaultPref("privacy.cpd.passwords", true);
defaultPref("privacy.cpd.siteSettings", true);
defaultPref("privacy.firstparty.isolate", true);
defaultPref("privacy.history.custom", true);
defaultPref("privacy.sanitize.sanitizeOnShutdown", true);
defaultPref("privacy.userContext.enabled", true);
defaultPref("privacy.userContext.ui.enabled", true);
defaultPref("privacy.userContext.longPressBehavior", 2);
defaultPref("privacy.usercontext.about_newtab_segregation.enabled", true);
defaultPref("security.insecure_connection_icon.enabled", true);
defaultPref("security.insecure_connection_icon.pbmode.enabled", true);
defaultPref("security.insecure_connection_text.enabled", true);
defaultPref("security.insecure_connection_text.pbmode.enabled", true);
defaultPref("security.mixed_content.upgrade_display_content", true);
defaultPref("security.family_safety.mode", 0);
defaultPref("signon.autofillForms", false);
defaultPref("signon.formlessCapture.enabled", false);
defaultPref("shield.savant.enabled", false);
defaultPref("startup.homepage_welcome_url", "");
defaultPref("toolkit.coverage.endpoint.base", "");
defaultPref("toolkit.coverage.opt-out", true);
defaultPref("toolkit.telemetry.archive.enabled", false);
defaultPref("toolkit.telemetry.coverage.opt-out", true);
defaultPref("toolkit.telemetry.hybridContent.enabled", false);
defaultPref("toolkit.telemetry.bhrPing.enabled", false);
defaultPref("toolkit.telemetry.firstShutdownPing.enabled", false);
defaultPref("toolkit.telemetry.newProfilePing.enabled", false);
defaultPref("toolkit.telemetry.shutdownPingSender.enabled", false);
defaultPref("toolkit.telemetry.updatePing.enabled", false);
defaultPref("toolkit.telemetry.server", "");
defaultPref("toolkit.telemetry.unified", false);
defaultPref("toolkit.telemetry.infoURL", "");


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
