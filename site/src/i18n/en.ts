import type { Strings } from './types';

export const en: Strings = {
  lang: 'en',
  htmlLang: 'en',
  ogLocale: 'en_US',
  meta: {
    title: 'Tagara · Speak. I’ll type.',
    description:
      'Voice dictation for Mac that runs entirely on your computer. Hold ⌥, speak, release: the text appears at your cursor. Free, open source, no account.',
    ogImageAlt: 'Tagara: Speak. I’ll type. The recording pill with its three bars.',
  },
  nav: {
    skip: 'Skip to content',
    label: 'Main',
    features: 'Features',
    privacy: 'Privacy',
    faq: 'FAQ',
    otherLang: 'PT',
    otherLangLabel: 'Ler em português',
  },
  hero: {
    title: 'Speak. I’ll type.',
    subtitle:
      'Voice dictation for Mac. Hold ⌥, speak, release: the text appears wherever your cursor is. Runs entirely on your computer. Free, no account.',
    download: 'Download for Mac',
    downloadVersion: 'Download v{version}',
    requirements: 'macOS 15 or later · Apple Silicon Mac (M1 and up)',
    demoDescription:
      'Demo: someone holds the right Option key, speaks, and the text appears in a terminal, a chat and an email.',
  },
  copy: { label: 'Copy', done: 'Copied!', failed: 'Selected it for you, just press ⌘C.' },
  demo: {
    listening: 'listening…',
    typing: 'typing…',
    scenes: [
      {
        app: 'terminal',
        title: 'Terminal — claude',
        speech: 'refactor this function and write tests for it',
        typed: 'Refactor this function and write tests for it.',
        context: ['~/projects/shop', '✻ Claude Code'],
      },
      {
        app: 'chat',
        title: 'Messages',
        speech: 'be there in ten minutes go ahead and order',
        typed: 'Be there in ten minutes, go ahead and order.',
        context: ['Bia', 'where are you? 🍕'],
      },
      {
        app: 'mail',
        title: 'New email',
        speech: 'here is this month’s report let me know if you have questions',
        typed: 'Here is this month’s report. Let me know if you have questions.',
        context: ['To: team@company.com', 'Subject: September report'],
      },
    ],
  },
  how: {
    title: 'Three steps. None of them is typing.',
    lead: 'Works in the terminal, Slack, WhatsApp, your browser and any text field.',
    steps: [
      { title: 'Hold ⌥', text: 'The right Option key becomes a talk button. Shortcuts with ⌥ keep working.' },
      { title: 'Speak', text: 'Your way, in English or Portuguese. You can even mix both in one sentence.' },
      { title: 'Release', text: 'In about 0.3 seconds the text shows up at your cursor.' },
    ],
    result: 'Speak. I’ll type.',
  },
  features: {
    title: 'Small on the outside. Smart on the inside.',
    items: [
      {
        id: 'offline',
        title: 'Works offline',
        text: 'Once the model is downloaded, dictation runs on your Mac’s Neural Engine. On a plane or in a café with no Wi-Fi, it just works.',
      },
      { id: 'fast', title: 'Actually fast', text: 'A sentence becomes text 0.2 to 0.4 seconds after you let go of the key.' },
      {
        id: 'bilingual',
        title: 'English and Portuguese',
        text: 'The model detects the language on every dictation, so mixed sentences come out right.',
      },
      { id: 'handsfree', title: 'Hands-free', text: 'Double-tap ⌥ to dictate long texts without holding the key. One tap finishes.' },
      {
        id: 'anyapp',
        title: 'In any app',
        text: 'Types wherever your cursor is and puts your clipboard back the way it was.',
      },
      {
        id: 'history',
        title: 'History that stays yours',
        text: 'Your last 50 dictations stay on your Mac, searchable, so you can copy back what got lost. You can turn it off.',
      },
    ],
    fastValue: '0.3 s',
    fastFrom: 'released',
    fastTo: 'typed',
    bilingualSamples: ['Merge the branch e manda pro review.', 'Faz o deploy before lunch.'],
    anyappFields: ['Search', 'Message', '$'],
    historySamples: [
      'Be there in ten minutes, go ahead and order.',
      'Refactor this function and write tests for it.',
      'Here is this month’s report. Let me know if you have questions.',
    ],
  },
  privacy: {
    title: 'Nothing leaves your Mac.',
    lead: 'Audio stays in memory while you speak and is gone right after. No server, no account, no telemetry. And the code is open, so you can check every line.',
    boundary: 'Your Mac',
    flow: ['⌥ key', 'Microphone', 'Neural Engine', 'Text at your cursor'],
    cloud: 'Cloud',
    codeLink: 'Read the code on GitHub',
  },
  honest: {
    title: 'No catch.',
    price: '$0',
    priceNote: 'No account. No subscription. Open source, MIT license.',
    notTitle: 'What Tagara doesn’t do',
    not: [
      'It doesn’t rewrite what you said with AI. You get what you said.',
      'It doesn’t record meetings or transcribe files.',
      'It doesn’t send anything to the cloud. Not even if you ask.',
    ],
  },
  devs: {
    title: 'Made for people who live in the terminal.',
    lead: 'Install with one line, update with the same line, and dictate straight into Claude Code. Native Swift, no Electron.',
    installNote: 'Downloads the latest version, installs it in Applications and opens it.',
    claudePrompt: 'Add pagination to the products route and update the tests.',
    source: 'View on GitHub',
    build: 'Build from source',
  },
  faq: {
    title: 'FAQ',
    items: [
      {
        q: 'Will it run on my Mac?',
        a: 'You need an Apple Silicon Mac (M1 or newer) with macOS 15 or later. Intel Macs aren’t supported, because the model runs on the Neural Engine.',
      },
      {
        q: 'Why does it ask for Microphone and Accessibility?',
        a: 'The microphone is to hear you while the key is down. Accessibility is to notice ⌥ and type into the app in focus. None of it leaves your Mac.',
      },
      {
        q: 'macOS says it can’t open the app. Now what?',
        a: 'Tagara isn’t signed with an Apple developer certificate yet. If you install from the Terminal, the warning doesn’t show up. From the DMG, allow it in System Settings → Privacy & Security → Open Anyway.',
      },
      {
        q: 'How much space does it take?',
        a: 'About 650 MB, almost all of it the voice model. It’s downloaded once, the first time you open the app.',
      },
      {
        q: 'How do I update?',
        a: 'The app tells you when a new version is out and updates itself in one click. You can also run the install command again.',
      },
      {
        q: 'Is there a Windows, Linux or iPhone version?',
        a: 'Not for now. Tagara is built for the Mac and uses features that only exist there.',
      },
      { q: 'How much does it cost?', a: 'Nothing. Tagara is free and open source, under the MIT license.' },
    ],
  },
  closing: { title: 'Hold ⌥ and go.', text: 'Free, light, no account. Takes a minute to install.' },
  footer: {
    tagline: 'Local voice dictation for macOS.',
    license: 'MIT License',
    source: 'Source code',
    releases: 'Releases',
  },
};
