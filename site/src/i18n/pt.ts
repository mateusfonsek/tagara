import type { Strings } from './types';

export const pt: Strings = {
  lang: 'pt',
  htmlLang: 'pt-BR',
  ogLocale: 'pt_BR',
  meta: {
    title: 'Tagara · Fala que eu escrevo',
    description:
      'Ditado por voz para Mac que roda inteiro no seu computador. Segura o ⌥, fala e solta: o texto aparece onde está o cursor. Grátis, código aberto, sem conta.',
    ogImageAlt: 'Tagara: Fala que eu escrevo. A pílula de gravação com as três barras.',
  },
  nav: {
    skip: 'Pular para o conteúdo',
    label: 'Principal',
    features: 'Recursos',
    privacy: 'Privacidade',
    faq: 'Dúvidas',
    otherLang: 'EN',
    otherLangLabel: 'Read in English',
  },
  hero: {
    title: 'Fala que eu escrevo.',
    subtitle:
      'Ditado por voz para Mac. Segura o ⌥, fala e solta: o texto aparece onde está o cursor. Roda inteiro no seu computador, grátis e sem conta.',
    download: 'Baixar para Mac',
    downloadVersion: 'Baixar v{version}',
    requirements: 'macOS 15 ou mais novo · Mac com Apple Silicon (M1 em diante)',
    demoDescription:
      'Demonstração: a pessoa segura a tecla Option da direita, fala, e o texto aparece num terminal, num chat e num e-mail.',
  },
  copy: { label: 'Copiar', done: 'Copiado!', failed: 'Selecionei pra você, é só ⌘C.', failedTouch: 'Selecionei pra você, é só copiar.' },
  demo: {
    listening: 'ouvindo…',
    typing: 'escrevendo…',
    scenes: [
      {
        app: 'terminal',
        title: 'Terminal — claude',
        speech: 'refatora essa função e escreve os testes pra ela',
        typed: 'Refatora essa função e escreve os testes pra ela.',
        context: ['~/projetos/loja', '✻ Claude Code'],
      },
      {
        app: 'chat',
        title: 'Mensagens',
        speech: 'chego em dez minutos pode ir pedindo',
        typed: 'Chego em dez minutos, pode ir pedindo.',
        context: ['Bia', 'cadê você? 🍕'],
      },
      {
        app: 'mail',
        title: 'Novo e-mail',
        speech: 'segue o relatório do mês qualquer dúvida me chama',
        typed: 'Segue o relatório do mês. Qualquer dúvida, me chama.',
        context: ['Para: equipe@empresa.com', 'Assunto: Relatório de setembro'],
      },
    ],
  },
  how: {
    title: 'Três passos. Nenhum é digitar.',
    lead: 'Funciona no terminal, no Slack, no WhatsApp, no navegador e em qualquer campo de texto.',
    steps: [
      { title: 'Segura o ⌥', text: 'O Option da direita vira um botão de falar. Atalhos com ⌥ continuam funcionando.' },
      { title: 'Fala', text: 'Do seu jeito, em português ou inglês. Pode até misturar os dois na mesma frase.' },
      { title: 'Solta', text: 'Em cerca de 0,3 segundo o texto aparece onde está o cursor.' },
    ],
    result: 'Fala que eu escrevo.',
  },
  features: {
    title: 'Pequeno por fora. Esperto por dentro.',
    items: [
      {
        id: 'offline',
        title: 'Funciona sem internet',
        text: 'Depois de baixar o modelo uma vez, o ditado roda no Neural Engine do seu Mac. No avião ou no café sem Wi-Fi, tanto faz.',
      },
      { id: 'fast', title: 'Rápido de verdade', text: 'Uma frase vira texto 0,2 a 0,4 segundo depois que você solta a tecla.' },
      {
        id: 'bilingual',
        title: 'Português e inglês',
        text: 'O modelo reconhece o idioma a cada ditado. Dá pra fazer o deploy da branch sem traduzir nada.',
      },
      { id: 'handsfree', title: 'Mãos livres', text: 'Toque duas vezes no ⌥ para ditar textos longos sem segurar. Um toque termina.' },
      {
        id: 'anyapp',
        title: 'Em qualquer app',
        text: 'Escreve onde está o cursor e devolve a sua área de transferência do jeito que estava.',
      },
      {
        id: 'history',
        title: 'Histórico só seu',
        text: 'Os últimos 50 ditados ficam guardados no seu Mac, com busca, para copiar de novo o que se perdeu. Dá pra desligar.',
      },
    ],
    fastValue: '0,3 s',
    fastFrom: 'soltou',
    fastTo: 'escrito',
    bilingualSamples: ['Faz o merge da branch e manda pro review.', 'Let’s ship it amanhã cedo.'],
    anyappFields: ['Buscar', 'Mensagem', '$'],
    historySamples: [
      'Chego em dez minutos, pode ir pedindo.',
      'Refatora essa função e escreve os testes pra ela.',
      'Segue o relatório do mês. Qualquer dúvida, me chama.',
    ],
  },
  privacy: {
    title: 'Nada sai do seu Mac.',
    lead: 'O áudio fica na memória enquanto você fala e some logo depois. Não tem servidor, conta nem telemetria. E o código é aberto: dá pra conferir cada linha.',
    boundary: 'Seu Mac',
    flow: ['Tecla ⌥', 'Microfone', 'Neural Engine', 'Texto no cursor'],
    cloud: 'Nuvem',
    codeLink: 'Ler o código no GitHub',
  },
  honest: {
    title: 'Sem pegadinha.',
    price: 'R$0',
    priceNote: 'Sem conta. Sem assinatura. Código aberto, licença MIT.',
    notTitle: 'O que o Tagara não faz',
    not: [
      'Não reescreve o que você disse com IA. Sai o que você falou.',
      'Não grava reuniões nem transcreve arquivos.',
      'Não manda nada para a nuvem. Nem se você pedir.',
    ],
  },
  devs: {
    title: 'Feito para quem vive no terminal.',
    lead: 'Instala com uma linha, atualiza com a mesma linha e dita direto no Claude Code. Swift nativo, sem Electron.',
    installNote: 'Baixa a última versão, instala em Aplicativos e abre o app.',
    claudePrompt: 'Adiciona paginação na rota de produtos e atualiza os testes.',
    source: 'Ver no GitHub',
    build: 'Compilar do código',
  },
  faq: {
    title: 'Dúvidas',
    items: [
      {
        q: 'Funciona no meu Mac?',
        a: 'Precisa de um Mac com Apple Silicon (M1 ou mais novo) e macOS 15 ou mais novo. Macs com Intel ficam de fora, porque o modelo roda no Neural Engine.',
      },
      {
        q: 'Por que ele pede Microfone e Acessibilidade?',
        a: 'O microfone é para ouvir enquanto a tecla está apertada. A Acessibilidade é para notar o ⌥ e escrever no app em foco. Nada disso sai do seu Mac.',
      },
      {
        q: 'O macOS disse que não pode abrir o app. E agora?',
        a: 'O Tagara ainda não é assinado com um certificado de desenvolvedor da Apple. Instalando pelo Terminal, o aviso não aparece. Pelo DMG, libere em Ajustes do Sistema → Privacidade e Segurança → Abrir mesmo assim.',
      },
      {
        q: 'Quanto espaço ocupa?',
        a: 'Cerca de 650 MB, quase tudo do modelo de voz. Ele é baixado uma vez só, na primeira abertura.',
      },
      {
        q: 'Como eu atualizo?',
        a: 'O app avisa quando sai versão nova e se atualiza com um clique. Também dá para rodar o comando de instalação de novo.',
      },
      {
        q: 'Tem para Windows, Linux ou iPhone?',
        a: 'Por enquanto, não. O Tagara é feito para o Mac e usa recursos que só existem nele.',
      },
      { q: 'Quanto custa?', a: 'Nada. O Tagara é gratuito e de código aberto, sob a licença MIT.' },
    ],
  },
  closing: { title: 'Segura ⌥ e manda ver.', text: 'Grátis, leve e sem conta. Leva um minuto para instalar.' },
  footer: {
    tagline: 'Ditado por voz local para macOS.',
    license: 'Licença MIT',
    source: 'Código-fonte',
    releases: 'Versões',
  },
};
