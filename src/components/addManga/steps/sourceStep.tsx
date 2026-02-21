import { Box, LoadingOverlay, MultiSelect } from '@mantine/core';
import { UseFormReturnType } from '@mantine/form';
import { trpc } from '../../../utils/trpc';
import type { FormType } from '../form';

export function SourceStep({ form }: { form: UseFormReturnType<FormType> }) {
  const query = trpc.manga.sources.useQuery(undefined, {
    staleTime: Infinity,
  });

  if (query.isLoading) {
    return <LoadingOverlay visible />;
  }

  const selectData = [
    { value: 'all', label: 'All Sources' },
    ...(query.data?.map((s) => ({
      value: s,
      label: s,
    })) || []),
  ];

  const handleSourceChange = (val: string[]) => {
    if (val.includes('all') && val[val.length - 1] === 'all') {
      form.setFieldValue('source', ['all']);
    } else if (val.includes('all') && val.length > 1) {
      form.setFieldValue(
        'source',
        val.filter((s) => s !== 'all'),
      );
    } else {
      form.setFieldValue('source', val);
    }
  };

  return (
    <Box>
      <MultiSelect
        data-autofocus
        data={selectData}
        label="Available sources"
        placeholder="Select source(s)"
        value={Array.isArray(form.values.source) ? form.values.source : [form.values.source]}
        onChange={handleSourceChange}
        error={form.errors.source}
      />
    </Box>
  );
}
