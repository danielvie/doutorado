## Ações realizadas

- Adicionada lógica de *dead time* em `z_kawa/signal_generate.m`:
  - definido `dead_time_us = 2`;
  - identificado o segmento ativo do ciclo e o segmento anterior;
  - comparado o modo atual com o modo anterior para detectar quais canais mudaram de estado;
  - aplicado bloqueio simultâneo dos sinais `High` e `Low` (`-1, -1`) apenas nos canais que mudam durante a janela de *dead time*;
  - incluída proteção também na transição de retorno do último segmento para o primeiro segmento do ciclo.

- Mantida a geração dos sinais complementares `u3High/u3Low`, `u2High/u2Low` e `u1High/u1Low` fora da janela de *dead time*.
