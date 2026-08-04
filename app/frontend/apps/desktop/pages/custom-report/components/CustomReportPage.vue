<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
interface Props {
  title: string
  // Sem sidebar na página de exportações, que não escolhe relatório.
  withSidebar?: boolean
}

withDefaults(defineProps<Props>(), { withSidebar: false })
</script>

<!--
  Casca própria em vez de LayoutContent: esta é uma guia independente, fora de
  LayoutPage, e LayoutContent depende do grid e das composables da navegação
  lateral da Desktop View. Aqui só há cabeçalho, barra lateral e conteúdo.
-->
<template>
  <div class="flex h-screen flex-col bg-blue-50 text-gray-100 dark:bg-gray-500 dark:text-neutral-400">
    <header
      class="flex flex-wrap items-center justify-between gap-3 border-b border-neutral-100 px-4 py-3 dark:border-gray-900"
    >
      <CommonLabel tag="h2" size="large">{{ $t(title) }}</CommonLabel>

      <div class="flex flex-wrap items-center gap-2">
        <slot name="actions" />
      </div>
    </header>

    <!-- min-h-0 para o conteúdo poder rolar dentro da altura da tela em vez de
         empurrar a página inteira. -->
    <div class="flex min-h-0 grow">
      <aside
        v-if="withSidebar"
        class="w-72 shrink-0 overflow-y-auto border-e border-neutral-100 p-3 dark:border-gray-900"
      >
        <slot name="sidebar" />
      </aside>

      <main class="flex min-w-0 grow flex-col gap-4 overflow-auto p-4">
        <slot />
      </main>
    </div>
  </div>
</template>
