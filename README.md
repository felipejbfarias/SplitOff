# 🍎 SplitOff

**SplitOff** é um app iOS, 100% local, para dividir a conta dos rolês entre amigos, sem servidor, sem cadastro, sem login. Você monta grupos, abre uma comanda no bar/restaurante, registra os pedidos item a item, diz quem dividiu o quê, e o app cuida do resto: taxa de serviço, couvert, quem pagou a mais, quem ficou devendo e a menor sequência de PIX para todo mundo ficar quitado.

Tudo roda no aparelho, sobre SwiftData. Nada sai do dispositivo, nem mesmo a foto do cardápio: o OCR e a IA que estruturam o cardápio rodam com Vision + Apple Intelligence / Foundation Models.

---

## 🧩 Conceitos centrais

| Conceito | O que é |
|---|---|
| **Grupo** | Uma turma de amigos. Tem seus membros e um saldo próprio por pessoa. Dívidas **nunca cruzam** entre grupos. |
| **Pessoa** | Um membro de um grupo. Carrega um saldo acumulado. |
| **Comanda** | Um rolê. Só pode existir **uma** comanda ativa por vez no app inteiro, pertence a um grupo e a um lugar. |
| **Pedido** | Uma rodada dentro da comanda, agrupa os itens consumidos. |
| **ItemPedido** | Um item consumido numa rodada, com preço e a lista de **donos** que o dividem igualmente entre si. |
| **Lugar** | O estabelecimento do rolê. Guarda um cardápio reutilizável entre comandas. |
| **Transferência** | Um PIX/pagamento registrado entre duas pessoas do mesmo grupo, que ajusta os saldos. |

---

## 👤 A regra do "Você"

O app é local, então o dono do aparelho é sempre o **"Você"**.

- Desde a primeira inicialização existe um grupo pessoal chamado **"Você"**, para as saídas sozinho. Ele é criado via CRUD.
- Todo grupo criado ganha o seu próprio "Você", uma `Pessoa` "Você" isolada por grupo. Como saldos não cruzam grupos, cada "Você" tem contas separadas.
- O "Você" participa obrigatoriamente de toda comanda, não faz sentido o dono do celular não participar uma vez que o app é local.
- O nome "Você" é reservado e não pode ser alterado: ninguém pode se chamar assim (as variáveis com/sem acentos e maiúsculas também são bloqueadas) e nem a pessoa "Você" nem o grupo "Você" podem ser renomeados ou removidos.

---

## ✨ Features em detalhe

### Grupos e saldos

Cada grupo agrega **pessoas**, **comandas** e **transferências**. Deletar um grupo apaga tudo isso em cascata, com exceção do grupo "Você".

O saldo de cada pessoa é a única fonte sobre quem deve a quem, e ele só muda por dois caminhos controlados:

1. **Fechamento de comanda**: A diferença entre o que a pessoa pagou e o que ela consumiu entra no saldo.
2. **Transferência**: Um PIX registrado ajusta os dois lados.


### Comandas, pedidos e divisão de itens

Uma comanda é o ponto central do app. Ela tem:

- **Rodadas de pedido** (`Pedido`), numeradas na ordem em que são abertas.
- **Itens** (`ItemPedido`), cada um com um preço e uma lista de donos, os participantes que dividem aquele item.
- **10% Opcional** (`cobraTaxaServico`), taxa de serviço de **10%** opcional a depender do estabelecimento.
- **Couvert por pessoa Opcional** (`valorCouvertPorPessoa`), se o estabelecimento cobra um valor por couvert ou não.
  
A conta de cada pessoa toda em `Decimal`, não utilizamos `Douvle` para dinheiro:

```
precoPorDono = preço do item / nº de donos
subtotalContaAtual = Somatório do precoPorDono dos itens que a pessoa dividiu
taxaServicoAtual = subtotal × 10% (se a comanda cobra taxa)
couvertArtisticoAtual = valorCouvertPorPessoa
contaAtual = subtotal + taxa + couvert
```

Divisão de item é igualitária entre os donos: Se 3 pessoas dividem um prato de R$30, cada uma deve R$10 dele. Um item precisa ter pelo menos um dono, e todo dono precisa ser participante da comanda.

Adicionar itens pode ser manual ou puxando do cardápio do lugar. Itens de pedido guardam uma referência opcional ao item do cardápio, então editar/remover o cardápio depois não corrompe o histórico de comandas passadas.

### Fechamento e saldo acumulado

A comanda só pode fechar quando o total pago bate com o total da conta, com uma tolerância de 1 centavo para absorver arredondamentos de centavos na divisão. Enquanto não bater, `fecharComanda` lança um erro explicando quanto falta.

Ao fechar, para cada participante:

```
pessoa.saldo += valorPago − contaAtual
```

Ou seja: quem pagou a mais vira credor com saldo positivo e quem pagou a menos vira devedor com saldo negativo. Como pagamentos e conta sempre se anulam em soma, o saldo do grupo permanece consistente.

> Pagamentos são registrados de forma incremental e o app impede pagar mais que o faltante na comanda.

### Quitação de dívidas (o algoritmo)

No fim, ninguém quer fazer 6 PIX quando 2 resolvem. O `PlanejadorQuitacaoDividas` calcula a menor quantidade de transferências para zerar todos os saldos do grupo, com um algoritmo guloso apoiado em dois heaps:

- Um max-heap de devedores, ou seja maior dívida no topo, e um max-heap de credores, ou seja maior crédito no topo. O `Heap<T>` é genérico, com comparador injetável.
- A cada rodada, casa o maior devedor com o maior credor, transfere `min(dívida, crédito)` e zera pelo menos um dos dois, quem sobra com valor faltante volta para o heap.

Isso garante o mínimo de transações na prática, sendo n−1 no pior caso, sempre priorizando quitar as maiores pontas primeiro.

> O algoritmo trabalha sobre cópias, não alterando o `saldo` das `Pessoa`. A sugestão é só uma proposta, então os saldos reais só devem mudar quando o usuário confirmar uma transferência, que aí é validada e enviada pelo `CRUD`.

### Scanner de cardápio (Vision + Apple Intelligence)

Em vez de digitar o cardápio inteiro, você pode tirar uma foto e o app estrutura os itens (nome + preço) para revisão. É um pipeline em duas camadas:

**1. OCR com layout (`LeitorTextoCardapio`, Vision)**
Ler o texto é a parte fácil, entender o layout é o desafio, para isso o leitor:
- Normaliza a foto (orientação e o limite de tamanho) antes do OCR.
- Corrige inclinação: estima o ângulo da foto pelos cantos dos fragmentos e busca o ângulo que melhor alinha os pares de texto.
- Detecta se existem duas colunas no cardápio: Procura um corte vertical que separe a página, evitando o clássico erro de juntar o nome do prato da esquerda com o preço da direita.
- Agrupa fragmentos em linhas pelo centro vertical corrigido, ordenando da esquerda para a direita.

**2. Estruturação com Apple Intelligence (`ExtratorItensCardapio`, Foundation Models)**
As linhas viram itens estruturados e utilizamos guided generation:
- Um tipo `@Generable` com `@Guide` obriga o modelo a devolver `nome` + `preco` no formato certo, sendo preço com vírgula.
- Instruções cuidadas lidam com os casos reais de cardápio brasileiro: nome que ocupa várias linhas, item com vários preços por tamanho, gramaturas que não são preço, e ignorar títulos de seção e descrições.
- O texto é dividido em blocos com sobreposição, cada um numa `LanguageModelSession` nova, o contexto de um bloco não "vaza" para o próximo, e a resposta chega por streaming.

**Se o aparelho não tem Apple Intelligence**, cai para um extrator por regex, que reconhece preços no fim da linha, inclusive múltiplos separados por `/`) e monta os itens a partir do texto puro. O scanner tenta funcionar mesmo sem a IA.

Nada disso grava direto no cardápio: os `ItemEscaneado` vão para uma tela de revisão onde o usuário confere, corrige os que precisam ser corrigidos, afinal o modelo pode cometer falhas, e só então confirma.

### Live Activity / Dynamic Island

Com uma comanda ativa, o rolê aparece fora do app via ActivityKit + WidgetKit:

- **Dynamic Island** mostra o seu gasto (`gastoDoVoce`) na hora.
- **Tela bloqueada** mostra o card do rolê: evento, lugar e o comparativo Você × Mesa (`totalMesa`).

O `GerenciadorLiveActivity` amarra o ciclo de vida da atividade ao da comanda: começa quando a comanda existe, atualiza sempre que os valores mudam e encerra quando ela fecha. Os valores ao vivo (`ContentState`) e os atributos do nome do evento e lugar são compartilhados com o target da extensão.

### Busca no histórico

A aba de busca filtra o histórico de comandas por nome do lugar ou por valor gasto por "Você", com o `gastoDoVoce` calculado por comanda. Comandas encerradas viram histórico consultável, sem afetar os saldos já fechados.

---

## 🏛 Arquitetura

O projeto separa as regra de arquitetura do app da interface forma clara. As regras vivem no `Backend/`, as telas só leem o `@Model` e chamam o `CRUD`.

| Pasta | Conteúdo |
|---|---|
| `Backend/Entidades/` | Modelos SwiftData (`@Model`) e seus cálculos derivados |
| `Backend/CRUD.swift` | Única porta de escrita no banco + todas as validações de regra |
| `Backend/QuitacaoDividas/` | `Heap` genérico, `PlanejadorQuitacaoDividas` (guloso) e `SugestaoTransferencia` |
| `Backend/ScannerCardapio/` | `LeitorTextoCardapio` (OCR/layout com Vision) e `ExtratorItensCardapio` (IA + extrator por regex) |
| `Backend/Persistencia.swift` | Monta o `ModelContainer` e garante o grupo "Você" |
| `Telas/` | Telas navegáveis |
| `Sheets/` | Sheets modais |
| `Componentes/` | Views reutilizáveis |
| `PopUp-Pickers/` | Popups de confirmação/destrutivos, seletor de menu e câmera |
| `LiveActivity/` | Atributos e gerenciador da Live Activity |
| `ExtensaoLiveActivity/` | Target da extensão de widget |

---

## 🗃 Modelo de dados

```
Grupo ──┬─< Pessoa ─────< ParticipanteComanda >─── Comanda
        │        (saldo)          (valorPago)         │
        ├─< Comanda ──< Pedido ──< ItemPedido >── donos (ParticipanteComanda)
        │                              │
        └─< Transferencia              └─ itemCardapio? ──> Item
                                                              │
Restaurante ──< Cardapio ──< Item ────────────────────────────┘
     └─< Comanda
```

Regras de deleção pensadas para preservar histórico:

- `Grupo` apaga em cascata suas `Pessoa`, `Comanda` e `Transferencia`.
- `Comanda` apaga em cascata `Pedido` e `ParticipanteComanda`.
- `ItemPedido → Item` e `Comanda → Restaurante` são `.nullify`: mexer no cardápio/lugar hoje não quebra comandas antigas.
- `ParticipanteComanda` e `Transferencia` guardam o nome da pessoa além da referência, para o histórico continuar legível mesmo se a pessoa for editada/removida.

---

## 🧭 Decisões de arquitetura

- `CRUD` como única porta de escrita, nenhuma view usa o `context` diretamente. Toda escrita e toda validação de regra, passa pelo `CRUD` que lança `CRUDErro` com mensagens prontas para a UI.

- **Regras de arquitetura no backend, não na UI.** As regras de negócio e implementação são todas garantidas pelo `CRUD`.

- **Dinheiro sempre em `Decimal`.** Preços, saldos, taxas e couvert nunca tocam `Double` evitando possível erro de ponto flutuante. O fechamento usa uma tolerância explícita de 1 centavo para arredondamentos da divisão.

- **Cálculo separado de efeito colateral.** As sugestões de quitação são computadas sobre cópias, sem tocar nos modelos, o saldo real só muda quando o usuário confirma.

- **Tudo Local (On-Device).** OCR + Vision e estruturação via Foundation Models rodam no aparelho.

- **Degradação graciosa.** Sem Apple Intelligence, o scanner cai para um extrator heurístico por regex. Sem Live Activities habilitadas, o app segue funcionando normalmente. As features avançadas não são pré-requisitos para o funcionamento.

- **Histórico à prova de edição.** Nomes são armazenados nos registros históricos e as referências mutáveis usam `.nullify`, então editar um cardápio ou uma pessoa hoje não altera as comandas passadas.

---

## 🛠 Tecnologias

- **Swift / SwiftUI**: UI declarativa e navegação
- **SwiftData**: persistência local com `@Model`, `ModelContainer`
- **Vision**: OCR com reconhecimento de texto e layout do cardápio
- **FoundationModels**: estruturação on-device com guided generation e streaming
- **ActivityKit + WidgetKit**: Live Activity, Dynamic Island e widget de tela bloqueada

---

## 👥 Time

Projeto **Apple Developer Academy**

**Davi Dubeux** · **Felipe Farias** · **Matheus Menezes**
