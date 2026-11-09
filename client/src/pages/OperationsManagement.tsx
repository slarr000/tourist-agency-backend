import { useEffect, useMemo, useState, type ChangeEvent } from 'react';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  MenuItem,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import { apiRequest } from '../lib/api';

type FieldType = 'text' | 'number' | 'date' | 'datetime-local' | 'select';

interface FieldDefinition {
  key: string;
  label: string;
  type?: FieldType;
  required?: boolean;
  options?: { label: string; value: string }[];
}

interface ResourceDefinition {
  id: string;
  label: string;
  endpoint: string;
  idField: string;
  fields: FieldDefinition[];
}

const resources: ResourceDefinition[] = [
  {
    id: 'flights', label: 'Рейсы', endpoint: '/api/Flights', idField: 'flight_id',
    fields: [
      { key: 'flight_number', label: 'Номер рейса', required: true },
      { key: 'flight_date', label: 'Дата рейса', type: 'date', required: true },
      { key: 'aircraft_type', label: 'Тип самолета', required: true },
      { key: 'flight_type', label: 'Тип рейса', type: 'select', required: true, options: [
        { label: 'Пассажирский', value: 'Пассажирский' },
        { label: 'Грузовой', value: 'Грузовой' },
        { label: 'Грузо-пассажирский', value: 'Грузо-пассажирский' },
      ] },
      { key: 'seat_capacity', label: 'Пассажирских мест', type: 'number', required: true },
    ],
  },
  {
    id: 'hotels', label: 'Гостиницы', endpoint: '/api/Hotels?PageNumber=1&PageSize=50', idField: 'hotel_id',
    fields: [
      { key: 'hotel_name', label: 'Название', required: true },
      { key: 'country', label: 'Страна', required: true },
      { key: 'stars_count', label: 'Звезды', type: 'number', required: true },
      { key: 'address', label: 'Адрес', required: true },
      { key: 'price_per_night', label: 'Цена за ночь', type: 'number', required: true },
    ],
  },
  {
    id: 'agencies', label: 'Экскурсионные агентства', endpoint: '/api/Agencies', idField: 'agency_id',
    fields: [
      { key: 'agency_name', label: 'Название агентства', required: true },
      { key: 'quality_rating', label: 'Оценка качества (0–10)', type: 'number', required: true },
    ],
  },
  {
    id: 'excursions', label: 'Экскурсии', endpoint: '/api/Excursions', idField: 'excursion_id',
    fields: [
      { key: 'agency_id', label: 'ID агентства', type: 'number', required: true },
      { key: 'excursion_name', label: 'Название экскурсии', required: true },
      { key: 'schedule_date', label: 'Дата и время', type: 'datetime-local', required: true },
      { key: 'price', label: 'Стоимость', type: 'number', required: true },
    ],
  },
  {
    id: 'bookings', label: 'Бронирования гостиниц', endpoint: '/api/Bookings', idField: 'booking_id',
    fields: [
      { key: 'tourist_id', label: 'ID туриста', type: 'number', required: true },
      { key: 'hotel_id', label: 'ID гостиницы', type: 'number', required: true },
      { key: 'check_in_date', label: 'Заезд', type: 'date', required: true },
      { key: 'check_out_date', label: 'Выезд', type: 'date', required: true },
      { key: 'room_number', label: 'Номер комнаты', required: true },
    ],
  },
  {
    id: 'finances', label: 'Доходы и расходы', endpoint: '/api/Finances', idField: 'transaction_id',
    fields: [
      { key: 'transaction_type', label: 'Тип операции', type: 'select', required: true, options: [
        { label: 'Доход', value: 'Доход' }, { label: 'Расход', value: 'Расход' },
      ] },
      { key: 'category', label: 'Статья', required: true },
      { key: 'amount', label: 'Сумма', type: 'number', required: true },
      { key: 'transaction_date', label: 'Дата', type: 'date', required: true },
      { key: 'description', label: 'Описание' },
      { key: 'flight_id', label: 'ID группы / рейса', type: 'number' },
      { key: 'tourist_id', label: 'ID туриста (если расход персональный)', type: 'number' },
    ],
  },
  {
    id: 'visits', label: 'Прибытия и отъезды', endpoint: '/api/TouristVisits', idField: 'visit_id',
    fields: [
      { key: 'tourist_id', label: 'ID туриста', type: 'number', required: true },
      { key: 'flight_id', label: 'ID рейса', type: 'number', required: true },
      { key: 'arrival_date', label: 'Дата прилета', type: 'date', required: true },
      { key: 'departure_date', label: 'Дата отъезда', type: 'date', required: true },
    ],
  },
  {
    id: 'passports', label: 'Паспортные данные', endpoint: '/api/Passports', idField: 'passport_id',
    fields: [
      { key: 'tourist_id', label: 'ID туриста', type: 'number', required: true },
      { key: 'type_passport', label: 'Тип паспорта', required: true },
      { key: 'passport_serial', label: 'Серия', required: true },
      { key: 'passport_number', label: 'Номер паспорта', required: true },
      { key: 'date_of_issue', label: 'Дата выдачи', type: 'date', required: true },
      { key: 'expiry_date', label: 'Срок действия до', type: 'date', required: true },
      { key: 'issued_by', label: 'Кем выдан', required: true },
      { key: 'latin_name', label: 'Имя латиницей', required: true },
      { key: 'department_code', label: 'Код подразделения', required: true },
      { key: 'registration_address', label: 'Адрес регистрации', required: true },
    ],
  },
  {
    id: 'children', label: 'Дети и документы', endpoint: '/api/TouristChildren', idField: 'child_id',
    fields: [
      { key: 'tourist_id', label: 'ID родителя', type: 'number', required: true },
      { key: 'first_name', label: 'Имя', required: true },
      { key: 'last_name', label: 'Фамилия', required: true },
      { key: 'patronymic', label: 'Отчество' },
      { key: 'date_of_birth', label: 'Дата рождения', type: 'date', required: true },
      { key: 'gender', label: 'Пол', type: 'select', required: true, options: [
        { label: 'Женский', value: 'Женский' }, { label: 'Мужской', value: 'Мужской' },
      ] },
      { key: 'birth_certificate_number', label: 'Номер свидетельства', required: true },
      { key: 'date_of_issue', label: 'Дата выдачи свидетельства', type: 'date', required: true },
      { key: 'issued_by', label: 'Кем выдано', required: true },
    ],
  },
  {
    id: 'excursion-bookings', label: 'Записи на экскурсии', endpoint: '/api/ExcursionBookings', idField: 'booking_id',
    fields: [
      { key: 'tourist_id', label: 'ID взрослого сопровождающего', type: 'number', required: true },
      { key: 'excursion_id', label: 'ID экскурсии', type: 'number', required: true },
      { key: 'child_id', label: 'ID ребенка (только с записью сопровождающего)', type: 'number' },
    ],
  },
];

type RecordData = Record<string, unknown>;

const toInputValue = (value: unknown, type: FieldType = 'text') => {
  if (value == null) return '';
  const text = String(value);
  if (type === 'date') return text.slice(0, 10);
  if (type === 'datetime-local') return text.slice(0, 16);
  return text;
};

const OperationsManagement = () => {
  const [resourceId, setResourceId] = useState(resources[0].id);
  const [records, setRecords] = useState<RecordData[]>([]);
  const [form, setForm] = useState<Record<string, string>>({});
  const [editingId, setEditingId] = useState<number | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const resource = useMemo(
    () => resources.find((item) => item.id === resourceId) ?? resources[0],
    [resourceId],
  );

  useEffect(() => {
    let active = true;
    apiRequest<unknown>(resource.endpoint)
      .then((result) => {
        if (!Array.isArray(result)) throw new Error('Сервер вернул данные в неожиданном формате.');
        if (active) {
          setRecords(result as RecordData[]);
          setError(null);
        }
      })
      .catch((requestError: unknown) => {
        if (active) setError(requestError instanceof Error ? requestError.message : 'Не удалось загрузить записи.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, [resource]);

  const startCreate = () => {
    setEditingId(null);
    setForm(Object.fromEntries(resource.fields.map((field) => [field.key, ''])));
    setError(null);
    setSuccess(null);
    setDialogOpen(true);
  };

  const startEdit = (record: RecordData) => {
    setEditingId(Number(record[resource.idField]));
    setForm(Object.fromEntries(resource.fields.map((field) => [
      field.key,
      toInputValue(record[field.key], field.type),
    ])));
    setError(null);
    setSuccess(null);
    setDialogOpen(true);
  };

  const closeDialog = () => {
    setDialogOpen(false);
    setEditingId(null);
  };

  const changeField = (field: FieldDefinition, event: ChangeEvent<HTMLInputElement>) => {
    setForm((current) => ({ ...current, [field.key]: event.target.value }));
  };

  const refreshRecords = async () => {
    const result = await apiRequest<unknown>(resource.endpoint);
    if (!Array.isArray(result)) throw new Error('Сервер вернул данные в неожиданном формате.');
    setRecords(result as RecordData[]);
  };

  const saveRecord = async () => {
    const missingField = resource.fields.find((field) => field.required && !form[field.key]?.trim());
    if (missingField) {
      setError(`Заполните поле «${missingField.label}».`);
      return;
    }

    const body = Object.fromEntries(resource.fields.map((field) => {
      const value = form[field.key]?.trim() ?? '';
      if (field.type === 'number') return [field.key, value === '' ? null : Number(value)];
      return [field.key, value === '' ? null : value];
    }));

    if (resource.id === 'bookings' && String(body.check_in_date) > String(body.check_out_date)) {
      setError('Дата выезда не может быть раньше даты заезда.');
      return;
    }
    if (resource.id === 'visits' && String(body.arrival_date) > String(body.departure_date)) {
      setError('Дата отъезда не может быть раньше даты прилета.');
      return;
    }

    setSaving(true);
    setError(null);
    setSuccess(null);
    try {
      const resourcePath = resource.endpoint.split('?')[0];
      const endpoint = editingId == null ? resourcePath : `${resourcePath}/${editingId}`;
      await apiRequest(endpoint, {
        method: editingId == null ? 'POST' : 'PUT',
        body: JSON.stringify(body),
      });
      await refreshRecords();
      closeDialog();
      setSuccess(editingId == null ? 'Запись создана.' : 'Изменения сохранены.');
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось сохранить запись.');
    } finally {
      setSaving(false);
    }
  };

  const deleteRecord = async (record: RecordData) => {
    const id = Number(record[resource.idField]);
    if (!Number.isInteger(id) || id < 1) {
      setError('У записи некорректный идентификатор; удаление отменено.');
      return;
    }
    if (!window.confirm(`Удалить запись №${id} (${resource.label.toLowerCase()})?`)) return;

    setError(null);
    setSuccess(null);
    try {
      await apiRequest(`${resource.endpoint.split('?')[0]}/${id}`, { method: 'DELETE' });
      await refreshRecords();
      setSuccess('Запись удалена.');
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось удалить запись.');
    }
  };

  const visibleFields = resource.fields;
  const inputStyle = {
    '& .MuiInputLabel-root': { color: '#aaa' },
    '& .MuiOutlinedInput-root': {
      color: '#fff',
      '& fieldset': { borderColor: 'rgba(255,255,255,0.2)' },
    },
  };

  return (
    <Box sx={{ maxWidth: 1400, mx: 'auto' }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2, flexWrap: 'wrap', mb: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ color: '#fff', fontWeight: 800 }}>Операции представительства</Typography>
          <Typography sx={{ color: '#aaa', mt: 0.5 }}>Ведение рейсов, размещения, документов, экскурсий, груза и финансов</Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={startCreate} sx={{ backgroundColor: '#61dafb', color: '#071018', fontWeight: 700 }}>
          Добавить запись
        </Button>
      </Box>

      <Paper sx={{ p: 2, mb: 2, backgroundColor: '#121212', border: '1px solid #292929' }}>
        <TextField
          select
          label="Раздел учета"
          value={resourceId}
          onChange={(event) => {
            setResourceId(event.target.value);
            setLoading(true);
            setRecords([]);
            setError(null);
            setSuccess(null);
          }}
          sx={{ ...inputStyle, minWidth: { xs: '100%', sm: 340 } }}
        >
          {resources.map((item) => <MenuItem key={item.id} value={item.id}>{item.label}</MenuItem>)}
        </TextField>
      </Paper>

      {error && !dialogOpen && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

      <TableContainer component={Paper} sx={{ backgroundColor: '#121212', border: '1px solid #292929' }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell sx={{ color: '#61dafb', fontWeight: 700 }}>ID</TableCell>
              {visibleFields.map((field) => <TableCell key={field.key} sx={{ color: '#61dafb', fontWeight: 700 }}>{field.label}</TableCell>)}
              <TableCell sx={{ color: '#61dafb', fontWeight: 700 }}>Действия</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow><TableCell colSpan={visibleFields.length + 2} align="center"><CircularProgress size={24} /></TableCell></TableRow>
            ) : records.length === 0 ? (
              <TableRow><TableCell colSpan={visibleFields.length + 2} align="center" sx={{ color: '#aaa', py: 4 }}>Записей нет.</TableCell></TableRow>
            ) : records.map((record, index) => {
              const id = record[resource.idField];
              return (
                <TableRow key={`${String(id)}-${index}`} hover>
                  <TableCell>{id == null ? '—' : String(id)}</TableCell>
                  {visibleFields.map((field) => {
                    const value = record[field.key];
                    return (
                      <TableCell key={field.key} sx={{ color: '#ddd', maxWidth: 260, overflowWrap: 'anywhere' }}>
                        {value == null || value === '' ? '—' : typeof value === 'object' ? JSON.stringify(value) : String(value)}
                      </TableCell>
                    );
                  })}
                  <TableCell sx={{ whiteSpace: 'nowrap' }}>
                    <IconButton aria-label="Редактировать" onClick={() => startEdit(record)}><EditIcon fontSize="small" /></IconButton>
                    <IconButton aria-label="Удалить" color="error" onClick={() => void deleteRecord(record)}><DeleteIcon fontSize="small" /></IconButton>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={dialogOpen} onClose={closeDialog} maxWidth="md" fullWidth>
        <DialogTitle>{editingId == null ? `Новая запись: ${resource.label.toLowerCase()}` : `Редактирование: ${resource.label.toLowerCase()}`}</DialogTitle>
        <DialogContent sx={{ pt: '16px !important' }}>
          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
            {resource.fields.map((field) => (
              <TextField
                key={field.key}
                select={field.type === 'select'}
                type={field.type === 'number' || field.type === 'date' || field.type === 'datetime-local' ? field.type : 'text'}
                label={field.label}
                value={form[field.key] ?? ''}
                onChange={(event) => changeField(field, event as ChangeEvent<HTMLInputElement>)}
                required={field.required}
                slotProps={field.type === 'date' || field.type === 'datetime-local' ? { inputLabel: { shrink: true } } : undefined}
                sx={inputStyle}
              >
                {field.options?.map((option) => (
                  <MenuItem key={option.value} value={option.value}>{option.label}</MenuItem>
                ))}
              </TextField>
            ))}
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={closeDialog}>Отмена</Button>
          <Button variant="contained" onClick={() => void saveRecord()} disabled={saving}>
            {saving ? <CircularProgress size={20} /> : 'Сохранить'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default OperationsManagement;
