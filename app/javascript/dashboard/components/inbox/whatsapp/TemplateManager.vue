<template>
  <div>
    <h2 class="text-xl font-bold mb-4">WhatsApp Templates</h2>

    <!-- Alert Box -->
    <div
      v-if="alert.message"
      :class="[
        'p-4 rounded mb-4',
        alert.type === 'success'
          ? 'bg-green-100 text-green-800'
          : 'bg-red-100 text-red-800'
      ]"
    >
      {{ alert.message }}
    </div>

    <form @submit.prevent="createTemplate" class="space-y-2 mb-6">
      <input v-model="form.name" placeholder="Template Name" type="text" required />

      <input v-model="form.language" placeholder="Language (e.g., en_US)" type="text" required />

      <select v-model="form.category" required style="margin-bottom: 16px">
        <option disabled value="">Select Category</option>
        <option value="MARKETING">MARKETING</option>
        <option value="UTILITY">UTILITY</option>
      </select>

      <input v-model="form.headerText" placeholder="Header Text" type="text" />

      <textarea
        v-model="form.bodyText"
        placeholder="Body Text (e.g., Hello {{1}})"
        style="margin-bottom: 16px"
        required
      ></textarea>

      <input v-model="form.footerText" placeholder="Footer Text" type="text" />

      <button
        class="px-4 py-2 bg-n-brand text-white rounded"
        type="submit"
        :disabled="isSubmitting"
        :class="{ 'opacity-50 cursor-not-allowed': isSubmitting }"
      >
        {{ isSubmitting ? 'Creating...' : 'Create Template' }}
      </button>
    </form>

    <div v-if="loading" class="text-center">Loading templates...</div>
    <div v-else>
      <div class="grid gap-4 sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
        <div
          v-for="tpl in templates"
          :key="tpl.id"
          class="bg-n-background p-6 rounded-2xl shadow-md border border-gray-100 hover:shadow-lg transition duration-300"
        >
          <h3 class="text-lg font-bold mb-2 text-gray-800">{{ tpl.name }}</h3>
          <p class="text-sm text-gray-600 mb-1"><strong>Status:</strong> {{ tpl.status }}</p>
          <p class="text-sm text-gray-600 mb-1"><strong>Language:</strong> {{ tpl.language }}</p>
          <p class="text-sm text-gray-600 mb-2"><strong>Category:</strong> {{ tpl.category }}</p>

          <div class="mt-2 space-y-1">
            <p v-for="c in tpl.components" :key="c.type" class="text-sm text-gray-700">
              <strong>{{ c.type }}:</strong> {{ c.text }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';
import { useStore } from 'vuex';

const store = useStore();
const accountId = computed(() => store.getters.getCurrentAccountId);

const templates = ref([]);
const loading = ref(true);
const alert = ref({ type: '', message: '' });
const isSubmitting = ref(false);

const form = ref({
  name: '',
  language: '',
  category: '',
  headerText: '',
  bodyText: '',
  footerText: ''
});

const fetchTemplates = async () => {
  loading.value = true;
  const { data } = await axios.get(`/api/v1/accounts/${accountId.value}/whatsapp_templates`);
  templates.value = data;
  loading.value = false;
};

function extractBodyExamples(text) {
  const matches = text.match(/{{\d+}}/g) || [];
  return matches.map((_, i) => `Example ${i + 1}`);
}

const createTemplate = async () => {
  isSubmitting.value = true;
  try {
    const payload = {
      name: form.value.name.toLowerCase().replace(/[^a-z0-9_]/g, '_'),
      language: form.value.language,
      category: form.value.category,
      components: []
    };

    if (form.value.headerText) {
      payload.components.push({
        type: 'HEADER',
        format: 'TEXT',
        text: form.value.headerText,
        example: {
          header_text: ['Example Header']
        }
      });
    }

    payload.components.push({
      type: 'BODY',
      text: form.value.bodyText,
      example: {
        body_text: extractBodyExamples(form.value.bodyText)
      }
    });

    if (form.value.footerText) {
      payload.components.push({
        type: 'FOOTER',
        text: form.value.footerText
      });
    }

    await axios.post(`/api/v1/accounts/${accountId.value}/whatsapp_templates`, { template: payload });

    alert.value = {
      type: 'success',
      message: 'Template created successfully.'
    };

    await fetchTemplates();

    form.value = {
      name: '',
      language: '',
      category: '',
      headerText: '',
      bodyText: '',
      footerText: ''
    };
  } catch (error) {
    const message =
      error.response?.data?.error?.error_user_msg ||
      'Something went wrong while creating the template.';
    alert.value = {
      type: 'error',
      message
    };
  } finally {
    isSubmitting.value = false;
    setTimeout(() => {
      alert.value = { type: '', message: '' };
    }, 10000);
  }
};

onMounted(fetchTemplates);
</script>

<style scoped>
.input {
  @apply w-full border p-2 rounded;
}
</style>
