<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
interface Props {
  title: string
}

defineProps<Props>()
</script>

<!--
  Casca própria em vez de LayoutContent: esta é uma guia independente, fora de
  LayoutPage, e LayoutContent depende do grid e das composables da navegação
  lateral da Desktop View. Aqui só há cabeçalho, ações e conteúdo.
-->
<template>
  <div class="flex min-h-screen flex-col bg-blue-50 text-gray-100 dark:bg-gray-500 dark:text-neutral-400">
    <header
      class="flex flex-wrap items-center justify-between gap-3 border-b border-neutral-100 px-4 py-3 dark:border-gray-900"
    >
      <CommonLabel tag="h2" size="large">{{ $t(title) }}</CommonLabel>

      <div class="flex flex-wrap items-center gap-2">
        <slot name="actions" />
      </div>
    </header>

    <main class="flex grow flex-col gap-4 p-4">
      <slot />
    </main>
  </div>
</template>
