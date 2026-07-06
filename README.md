# 🍎 SplitOff

App iOS 100% local para dividir contas de rolês entre amigos, comandas e pedidos,
divisão de itens, pagamentos e quitação de dívidas, sem servidor e sem cadastro.

## Como funciona

- **Grupos**: cada turma de amigos é um grupo, com seus membros e saldos próprios.
- **Comandas**: um rolê ativo por vez. Cada comanda tem rodadas de pedidos, itens
  divididos entre participantes e taxa de serviço de 10%.
- **Pagamentos**: ao encerrar a comanda, quem pagou a mais vira credor e quem pagou
  a menos vira devedor no saldo acumulado do grupo.
- **Quitação**: o app sugere o menor número possível de transferências para zerar
  as dívidas do grupo (algoritmo guloso com heap: maior devedor ↔ maior credor).
- **Busca**: histórico de comandas filtrável por nome do lugar ou pelo valor gasto.
- **Live Activity**: com uma comanda ativa, a Dynamic Island mostra o seu gasto e a
  tela bloqueada mostra o card do rolê (evento, lugar, Você × Mesa).

## A regra do Você

O app é local, então o dono do aparelho é o **"Você"** — uma regra de negócio central:

- Existe desde a primeira inicialização um **grupo pessoal "Você"** (saídas solo).
- Todo grupo criado ganha o seu **próprio** "Você" (saldos isolados por grupo —
  dívidas nunca cruzam entre grupos).
- O "Você" participa de **toda comanda**, obrigatoriamente, e é **imutável**:
  não pode ser renomeado nem removido. O nome "Você" é reservado.
- Tudo isso é garantido no backend (`CRUD`), não só na interface.

## Arquitetura

| Pasta | Conteúdo |
|---|---|
| `Backend/` | Entidades SwiftData, `CRUD`, `Persistencia`, algoritmo de quitação |
| `Telas/` | Telas navegáveis (tabs Comanda, Grupos e Busca + fluxo de novo pedido) |
| `Sheets/` | Sheets modais (criar/editar grupo, cardápio, pagamento, quitação) |
| `Componentes/` | Views reutilizáveis (rows, cards, pickers, barra de progresso) |
| `PopUp-Pickers/` | Popups de confirmação/destrutivos e seletor de menu |
| `LiveActivity/` | Atributos e gerenciador da Live Activity (compartilhados com a extensão) |
| `ExtensaoLiveActivity/` | Target da extensão de widget (Dynamic Island + tela bloqueada) |

**Convenções**: escrita no banco sempre via `CRUD`, nunca `context` direto nas views;
cálculos de sugestão trabalham em cópias, nunca mutam `@Model`, erros aparecem na UI
via catch e mensagem de erro.

## Tecnólogias utilizadas:

- Swift / SwiftUI / SwiftData / ActivityKit / WidgetKit

## Time

Projeto Apple Developer Academy
Matheus Menezes · Felipe Farias · Davi Dubeux
