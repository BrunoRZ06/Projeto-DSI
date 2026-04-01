🏠 BairroMatch - Encontre Sua Vibe
O BairroMatch é um aplicativo mobile desenvolvido para transformar a forma como viajantes escolhem onde se hospedar. Em vez de focar apenas no imóvel, o app foca no estilo de vida e nas preferências do usuário, recomendando bairros específicos que dão "match" com o perfil do viajante.

🚀 Funcionalidades Principais
Algoritmo de Match: Quiz interativo com sliders para definir prioridades de orçamento, proximidade de pontos turísticos e níveis de segurança.

Exploração Inteligente: Visualização de bairros em mapas interativos com estatísticas em tempo real (custo médio, índice de caminhabilidade e densidade de serviços como cafés).

Gamificação (Missões Locais): Incentivo à exploração autêntica da cidade através de desafios que rendem XP (ex: "Fotografe uma padaria local" ou "Encontre música ao vivo").

Perfil do Viajante: Acompanhamento de cidades exploradas, missões concluídas e estatísticas de progresso.

🛠️ Tecnologias Utilizadas
Front-end: FlutterFlow (Framework baseado em Flutter para UI de alta performance).

Lógica de Negócio: Dart (Custom Actions para cálculo do algoritmo de match).

Design: UI/UX moderna com foco em usabilidade e feedback visual imediato.

Geolocalização: Integração com Google Maps API.

📱 Visual do Projeto
O design segue uma linha limpa e moderna, com componentes personalizados para uma experiência mobile nativa:

Tela de Match: Onde a mágica acontece. O usuário define os parâmetros da sua viagem.

Explorar: Visualização detalhada do bairro recomendado com fotos da comunidade e dados técnicos.

Missões: A camada de gamificação que transforma a viagem em um jogo de descoberta.

Perfil: Dashboard pessoal do usuário para gerenciar sua jornada.

📐 Estrutura de Dados (Sugestão de Backend)
Para suportar as funcionalidades das telas, o projeto prevê a seguinte estrutura:

Bairros: id, nome, geometria_mapa, preco_medio, score_seguranca, score_turismo.

Missões: id, titulo, descricao, xp_reward, categoria.

Users: nome, email, xp_total, conquistas.

Supabase ==> https://supabase.com/dashboard/project/cxzwnafmfgpugwuunsyg
