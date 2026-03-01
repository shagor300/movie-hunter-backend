/**
 * FlixHub — Admin Remote Config Manager
 * ======================================
 * Node.js script to update Firebase Remote Config values from the Admin Panel.
 *
 * SETUP:
 *   1. Go to Firebase Console → Project Settings → Service Accounts
 *   2. Click "Generate New Private Key" → save as `service-account.json`
 *   3. Place it in the same directory as this script
 *   4. Run: npm install firebase-admin
 *   5. Run: node update_remote_config.js
 *
 * USAGE:
 *   // Update version and publish:
 *   node update_remote_config.js --version "1.2.0+3" --url "https://example.com/FlixHub_v1.2.0.apk" --force false --whats_new "Bug fixes,New UI,Performance boost"
 *
 *   // Force update:
 *   node update_remote_config.js --version "2.0.0+10" --url "https://example.com/FlixHub_v2.0.0.apk" --force true
 *
 *   // View current config:
 *   node update_remote_config.js --view
 */

const admin = require("firebase-admin");
const serviceAccount = require("./service-account.json");

// Initialize Firebase Admin SDK
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

// ── Parse CLI arguments ──
function parseArgs() {
    const args = {};
    const argv = process.argv.slice(2);

    for (let i = 0; i < argv.length; i++) {
        if (argv[i].startsWith("--")) {
            const key = argv[i].slice(2);
            const value = argv[i + 1] && !argv[i + 1].startsWith("--") ? argv[i + 1] : "true";
            args[key] = value;
            if (value !== "true") i++;
        }
    }
    return args;
}

// ── View current Remote Config ──
async function viewConfig() {
    const config = admin.remoteConfig();
    const template = await config.getTemplate();

    console.log("\n📋 Current Remote Config:\n");

    const params = template.parameters || {};
    for (const [key, param] of Object.entries(params)) {
        const defaultVal = param.defaultValue?.value || "(not set)";
        console.log(`  ${key}: ${defaultVal}`);
    }
    console.log("");
}

// ── Update Remote Config ──
async function updateConfig(args) {
    const config = admin.remoteConfig();

    // Get existing template
    let template;
    try {
        template = await config.getTemplate();
    } catch (e) {
        // If no template exists, create a new one
        template = { parameters: {}, conditions: [] };
    }

    if (!template.parameters) {
        template.parameters = {};
    }

    // Update parameters
    if (args.version) {
        template.parameters["current_version"] = {
            defaultValue: { value: args.version },
            description: "Current app version in format: name+buildNumber (e.g. 1.2.0+5)",
        };
    }

    if (args.url) {
        template.parameters["update_url"] = {
            defaultValue: { value: args.url },
            description: "APK download URL for app updates",
        };
    }

    if (args.force !== undefined) {
        template.parameters["is_force_update"] = {
            defaultValue: { value: args.force === "true" ? "true" : "false" },
            description: "If true, shows non-dismissible update dialog",
        };
    }

    if (args.whats_new) {
        template.parameters["whats_new"] = {
            defaultValue: { value: args.whats_new },
            description: "Comma-separated changelog items",
        };
    }

    // Validate and publish
    try {
        const validated = await config.validateTemplate(template);
        const published = await config.publishTemplate(validated);

        console.log("\n✅ Remote Config updated and published!");
        console.log("   ETag:", published.etag);
        console.log("\n📋 Published values:");

        if (args.version) console.log(`   current_version: ${args.version}`);
        if (args.url) console.log(`   update_url: ${args.url}`);
        if (args.force !== undefined) console.log(`   is_force_update: ${args.force}`);
        if (args.whats_new) console.log(`   whats_new: ${args.whats_new}`);

        console.log("\n🔄 Changes are live! Users will see the update on next app launch.\n");
    } catch (e) {
        console.error("\n❌ Failed to publish:", e.message);
    }
}

// ── Main ──
async function main() {
    const args = parseArgs();

    if (args.view) {
        await viewConfig();
    } else if (args.version || args.url || args.force !== undefined || args.whats_new) {
        console.log("\n📤 Updating Remote Config for FlixHub...");
        await updateConfig(args);
    } else {
        console.log(`
╔═══════════════════════════════════════════════════╗
║   FlixHub — Remote Config Admin Manager           ║
╠═══════════════════════════════════════════════════╣
║                                                   ║
║  USAGE:                                           ║
║                                                   ║
║  View current config:                             ║
║    node update_remote_config.js --view             ║
║                                                   ║
║  Push optional update:                            ║
║    node update_remote_config.js \\                  ║
║      --version "1.2.0+3" \\                        ║
║      --url "https://..." \\                        ║
║      --force false \\                              ║
║      --whats_new "Fix bugs,New feature"           ║
║                                                   ║
║  Push FORCE update:                               ║
║    node update_remote_config.js \\                  ║
║      --version "2.0.0+10" \\                       ║
║      --url "https://..." \\                        ║
║      --force true                                 ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
    `);
    }

    process.exit(0);
}

main().catch(console.error);
