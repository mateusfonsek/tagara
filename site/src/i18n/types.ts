export type Lang = 'pt' | 'en';
export type DemoApp = 'terminal' | 'chat' | 'mail';
export type FeatureId = 'offline' | 'fast' | 'bilingual' | 'handsfree' | 'anyapp' | 'history';

export interface DemoScene {
  app: DemoApp;
  /** Window title. */
  title: string;
  /** What the person says, lowercase, as a spoken caption. */
  speech: string;
  /** What Tagara pastes: capitalized and punctuated. */
  typed: string;
  /**
   * Scene furniture. terminal: [path line, banner]. chat: [contact name, their message].
   * mail: [to line, subject line].
   */
  context: [string, string];
}

export interface Strings {
  lang: Lang;
  htmlLang: string;
  ogLocale: string;
  meta: { title: string; description: string; ogImageAlt: string };
  nav: {
    skip: string;
    label: string;
    features: string;
    privacy: string;
    faq: string;
    otherLang: string;
    otherLangLabel: string;
  };
  hero: {
    title: string;
    subtitle: string;
    download: string;
    /** Must contain "{version}". */
    downloadVersion: string;
    requirements: string;
    demoDescription: string;
  };
  copy: { label: string; done: string; failed: string; failedTouch: string };
  demo: { listening: string; typing: string; scenes: DemoScene[] };
  how: { title: string; lead: string; steps: { title: string; text: string }[]; result: string };
  features: {
    title: string;
    items: { id: FeatureId; title: string; text: string }[];
    fastValue: string;
    fastFrom: string;
    fastTo: string;
    bilingualSamples: string[];
    anyappFields: string[];
    historySamples: string[];
  };
  privacy: {
    title: string;
    lead: string;
    boundary: string;
    flow: string[];
    cloud: string;
    codeLink: string;
  };
  honest: { title: string; price: string; priceNote: string; notTitle: string; not: string[] };
  devs: { title: string; lead: string; installNote: string; claudePrompt: string; source: string; build: string };
  faq: { title: string; items: { q: string; a: string }[] };
  closing: { title: string; text: string };
  footer: { tagline: string; license: string; source: string; releases: string };
}
