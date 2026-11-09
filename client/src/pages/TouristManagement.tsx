import React, { useCallback, useEffect, useState } from 'react';
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
  TablePagination,
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
import SearchIcon from '@mui/icons-material/Search';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import { Collapse, InputAdornment } from '@mui/material';
import { apiRequest } from '../lib/api';

interface Passport {
  passport_id: number;
  tourist_id: number;
  type_passport: string;
  passport_serial: string;
  passport_number: string;
  date_of_issue: string;
  expiry_date: string;
  issued_by: string;
  latin_name: string;
  department_code: string;
  registration_address: string;
}

interface Child {
  child_id: number;
  tourist_id: number;
  first_name: string;
  last_name: string;
  patronymic?: string | null;
  date_of_birth: string;
  gender: string;
  birth_certificate_number: string;
}

interface Tourist {
  tourist_id: number;
  tourist_name: string;
  tourist_surname: string;
  tourist_patronymic: string;
  tourist_date_of_birth: string;
  tourist_gender: string;
  tourist_children: string;
  tourist_cargo: string;
  flight_id: number | null;
  category: string;
  has_visa: boolean;
}

interface TouristForm extends Omit<Tourist, 'tourist_id' | 'flight_id' | 'tourist_date_of_birth'> {
  tourist_date_of_birth: string;
  flight_id: string;
}

interface PassportForm extends Omit<Passport, 'passport_id' | 'tourist_id' | 'date_of_issue' | 'expiry_date'> {
  date_of_issue: string;
  expiry_date: string;
}

const emptyForm: TouristForm = {
  tourist_name: '',
  tourist_surname: '',
  tourist_patronymic: '',
  tourist_date_of_birth: '',
  tourist_gender: '',
  tourist_children: 'Нет',
  tourist_cargo: 'Нет',
  flight_id: '',
  category: '',
  has_visa: false,
};

const emptyPassport: PassportForm = {
  type_passport: '',
  passport_serial: '',
  passport_number: '',
  date_of_issue: '',
  expiry_date: '',
  issued_by: '',
  latin_name: '',
  department_code: '',
  registration_address: '',
};

const TouristManagement: React.FC = () => {
  const [tourists, setTourists] = useState<Tourist[]>([]);
  const [children, setChildren] = useState<Child[]>([]);
  const [passports, setPassports] = useState<Passport[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [open, setOpen] = useState(false);
  const [editingTourist, setEditingTourist] = useState<Tourist | null>(null);
  const [form, setForm] = useState<TouristForm>(emptyForm);
  const [passportForm, setPassportForm] = useState<PassportForm>(emptyPassport);
  const [filters, setFilters] = useState({ search: '', category: '', parentId: '', family: '' });
  const [expandedTouristId, setExpandedTouristId] = useState<number | null>(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [error, setError] = useState<string | null>(null);

  const loadTourists = useCallback(async () => {
    try {
      const [touristData, childData, passportData] = await Promise.all([
        apiRequest<Tourist[]>('/api/Tourists'),
        apiRequest<Child[]>('/api/TouristChildren'),
        apiRequest<Passport[]>('/api/Passports'),
      ]);
      setTourists(touristData);
      setChildren(childData);
      setPassports(passportData);
      setError(null);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось загрузить список туристов.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let active = true;
    Promise.all([
      apiRequest<Tourist[]>('/api/Tourists'),
      apiRequest<Child[]>('/api/TouristChildren'),
      apiRequest<Passport[]>('/api/Passports'),
    ])
      .then(([touristData, childData, passportData]) => {
        if (!active) return;
        setTourists(touristData);
        setChildren(childData);
        setPassports(passportData);
        setError(null);
      })
      .catch((requestError: unknown) => {
        if (active) setError(requestError instanceof Error ? requestError.message : 'Не удалось загрузить список туристов.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, []);

  const openForm = (tourist?: Tourist) => {
    setEditingTourist(tourist ?? null);
    setForm(tourist ? {
      tourist_name: tourist.tourist_name,
      tourist_surname: tourist.tourist_surname,
      tourist_patronymic: tourist.tourist_patronymic ?? '',
      tourist_date_of_birth: tourist.tourist_date_of_birth.slice(0, 10),
      tourist_gender: tourist.tourist_gender,
      tourist_children: tourist.tourist_children,
      tourist_cargo: tourist.tourist_cargo,
      flight_id: tourist.flight_id?.toString() ?? '',
      category: tourist.category,
      has_visa: tourist.has_visa,
    } : emptyForm);
    const passport = tourist ? passports.find((item) => item.tourist_id === tourist.tourist_id) : undefined;
    setPassportForm(passport ? {
      type_passport: passport.type_passport,
      passport_serial: passport.passport_serial,
      passport_number: passport.passport_number,
      date_of_issue: passport.date_of_issue.slice(0, 10),
      expiry_date: passport.expiry_date.slice(0, 10),
      issued_by: passport.issued_by,
      latin_name: passport.latin_name,
      department_code: passport.department_code,
      registration_address: passport.registration_address,
    } : emptyPassport);
    setError(null);
    setOpen(true);
  };

  const closeForm = () => {
    setOpen(false);
    setEditingTourist(null);
    setForm(emptyForm);
    setPassportForm(emptyPassport);
  };

  const saveTourist = async () => {
    if (!form.tourist_name.trim() || !form.tourist_surname.trim() || !form.tourist_date_of_birth || !form.tourist_gender || !form.category) {
      setError('Заполните имя, фамилию, дату рождения, пол и категорию.');
      return;
    }

    setSaving(true);
    setError(null);
    const body = {
      ...form,
      tourist_name: form.tourist_name.trim(),
      tourist_surname: form.tourist_surname.trim(),
      tourist_patronymic: form.tourist_patronymic.trim() || null,
      flight_id: form.flight_id ? Number(form.flight_id) : null,
    };

    try {
      let savedTouristId = editingTourist?.tourist_id;
      if (editingTourist) {
        await apiRequest(`/api/Tourists/${editingTourist.tourist_id}`, { method: 'PUT', body: JSON.stringify(body) });
      } else {
        const created = await apiRequest<Tourist>('/api/Tourists', { method: 'POST', body: JSON.stringify(body) });
        savedTouristId = created.tourist_id;
        setEditingTourist(created);
      }
      const passportValues = Object.values(passportForm).map((value) => value.trim());
      const hasPassport = passportValues.some(Boolean);
      if (hasPassport) {
        const missingPassportFields = Object.entries(passportForm).filter(([, value]) => !value.trim());
        if (missingPassportFields.length) {
          setError('Турист сохранен. Заполните все поля паспортных данных или очистите их, чтобы оставить паспорт без изменений.');
          await loadTourists();
          return;
        }
        const currentPassport = passports.find((item) => item.tourist_id === savedTouristId);
        const passportBody = { ...passportForm, tourist_id: savedTouristId };
        if (currentPassport) {
          await apiRequest(`/api/Passports/${currentPassport.passport_id}`, { method: 'PUT', body: JSON.stringify(passportBody) });
        } else {
          await apiRequest('/api/Passports', { method: 'POST', body: JSON.stringify(passportBody) });
        }
      }
      closeForm();
      await loadTourists();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось сохранить туриста.');
    } finally {
      setSaving(false);
    }
  };

  const deleteTourist = async (tourist: Tourist) => {
    if (!window.confirm(`Удалить туриста ${tourist.tourist_surname} ${tourist.tourist_name}?`)) return;
    setError(null);
    try {
      await apiRequest(`/api/Tourists/${tourist.tourist_id}`, { method: 'DELETE' });
      await loadTourists();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось удалить туриста.');
    }
  };

  const fieldStyles = {
    '& .MuiInputLabel-root': { color: 'text.secondary' },
  };

  const filteredTourists = tourists.filter((tourist) => {
    const touristChildren = children.filter((child) => child.tourist_id === tourist.tourist_id);
    const fullName = [tourist.tourist_surname, tourist.tourist_name, tourist.tourist_patronymic].join(' ').toLocaleLowerCase();
    const childNames = touristChildren.map((child) => `${child.last_name} ${child.first_name} ${child.patronymic ?? ''}`).join(' ').toLocaleLowerCase();
    const searchMatches = `${fullName} ${childNames} ${tourist.tourist_id}`.includes(filters.search.trim().toLocaleLowerCase());
    const familyMatches = filters.family === ''
      || (filters.family === 'with-children' ? touristChildren.length > 0 : touristChildren.length === 0);
    return searchMatches
      && (!filters.category || tourist.category === filters.category)
      && (!filters.parentId || tourist.tourist_id === Number(filters.parentId))
      && familyMatches;
  });

  const pagedTourists = filteredTourists.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);

  return (
    <Box sx={{ maxWidth: 1200, mx: 'auto' }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ color: '#fff', fontWeight: 800 }}>Управление туристами</Typography>
          <Typography sx={{ color: '#aaa', mt: 0.5 }}>Карточки туристов, данные для визы и принадлежность к группе</Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => openForm()} sx={{ backgroundColor: '#61dafb', color: '#061018', fontWeight: 700 }}>
          Добавить туриста
        </Button>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      <Paper sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '2fr 1fr 1fr 1fr' }, gap: 1.5, p: 2, mb: 2 }}>
        <TextField
          size="small"
          label="Поиск: турист или ребенок"
          value={filters.search}
          onChange={(event) => { setFilters({ ...filters, search: event.target.value }); setPage(0); }}
          slotProps={{ input: { startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> } }}
        />
        <TextField
          select
          size="small"
          label="Категория"
          value={filters.category}
          onChange={(event) => { setFilters({ ...filters, category: event.target.value }); setPage(0); }}
        >
          <MenuItem value="">Все категории</MenuItem>
          {Array.from(new Set(tourists.map((tourist) => tourist.category).filter(Boolean))).map((category) => (
            <MenuItem key={category} value={category}>{category}</MenuItem>
          ))}
        </TextField>
        <TextField
          select
          size="small"
          label="Родитель / сопровождающий"
          value={filters.parentId}
          onChange={(event) => { setFilters({ ...filters, parentId: event.target.value }); setPage(0); }}
        >
          <MenuItem value="">Все туристы</MenuItem>
          {tourists.filter((tourist) => children.some((child) => child.tourist_id === tourist.tourist_id)).map((parent) => (
            <MenuItem key={parent.tourist_id} value={String(parent.tourist_id)}>
              #{parent.tourist_id} {[parent.tourist_surname, parent.tourist_name].join(' ')}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          size="small"
          label="Сопровождаемые дети"
          value={filters.family}
          onChange={(event) => { setFilters({ ...filters, family: event.target.value }); setPage(0); }}
        >
          <MenuItem value="">Все</MenuItem>
          <MenuItem value="with-children">Есть привязанные дети</MenuItem>
          <MenuItem value="without-children">Без привязанных детей</MenuItem>
        </TextField>
      </Paper>
      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow>
            {['', 'ID', 'ФИО / привязанные дети', 'Дата рождения', 'Пол', 'Категория', 'Виза', 'Рейс', 'Действия'].map((title) => (
              <TableCell key={title} sx={{ color: '#aaa', fontWeight: 700 }}>{title}</TableCell>
            ))}
          </TableRow></TableHead>
          <TableBody>
            {loading ? (
              <TableRow><TableCell colSpan={9} align="center"><CircularProgress size={24} /></TableCell></TableRow>
            ) : filteredTourists.length === 0 ? (
              <TableRow><TableCell colSpan={9} align="center" sx={{ color: 'text.secondary', py: 4 }}>По выбранным фильтрам туристы не найдены.</TableCell></TableRow>
            ) : pagedTourists.map((tourist) => {
              const linkedChildren = children.filter((child) => child.tourist_id === tourist.tourist_id);
              const expanded = expandedTouristId === tourist.tourist_id;
              return <React.Fragment key={tourist.tourist_id}>
              <TableRow hover>
                <TableCell padding="checkbox">
                  {linkedChildren.length > 0 && (
                    <IconButton
                      size="small"
                      aria-label={expanded ? 'Свернуть список детей' : 'Показать привязанных детей'}
                      onClick={() => setExpandedTouristId(expanded ? null : tourist.tourist_id)}
                    >
                      {expanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                    </IconButton>
                  )}
                </TableCell>
                <TableCell>#{tourist.tourist_id}</TableCell>
                <TableCell>
                  {[tourist.tourist_surname, tourist.tourist_name, tourist.tourist_patronymic].filter(Boolean).join(' ')}
                  <Typography variant="caption" sx={{ display: 'block' }} color="text.secondary">
                    {linkedChildren.length ? `Сопровождает детей: ${linkedChildren.length}` : 'Дети не привязаны'}
                  </Typography>
                </TableCell>
                <TableCell>{tourist.tourist_date_of_birth.slice(0, 10)}</TableCell>
                <TableCell>{tourist.tourist_gender}</TableCell>
                <TableCell>{tourist.category}</TableCell>
                <TableCell>{tourist.has_visa ? 'Оформлена' : 'Нет'}</TableCell>
                <TableCell>{tourist.flight_id ?? '—'}</TableCell>
                <TableCell>
                  <IconButton aria-label="Редактировать" onClick={() => openForm(tourist)}><EditIcon /></IconButton>
                  <IconButton aria-label="Удалить" onClick={() => void deleteTourist(tourist)} color="error"><DeleteIcon /></IconButton>
                </TableCell>
              </TableRow>
              {linkedChildren.length > 0 && (
                <TableRow>
                  <TableCell colSpan={9} sx={{ py: 0, borderBottom: expanded ? undefined : 0 }}>
                    <Collapse in={expanded} timeout="auto" unmountOnExit>
                      <Box sx={{ py: 2, pl: { xs: 1, sm: 8 } }}>
                        <Typography variant="subtitle2" sx={{ mb: 1 }}>
                          Дети под сопровождением {[tourist.tourist_surname, tourist.tourist_name].join(' ')}
                        </Typography>
                        {linkedChildren.map((child) => (
                          <Typography key={child.child_id} variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                            #{child.child_id} · {[child.last_name, child.first_name, child.patronymic].filter(Boolean).join(' ')}
                            {' · '}{child.date_of_birth.slice(0, 10)} · {child.gender} · свидетельство: {child.birth_certificate_number}
                          </Typography>
                        ))}
                      </Box>
                    </Collapse>
                  </TableCell>
                </TableRow>
              )}
              </React.Fragment>;
            })}
          </TableBody>
        </Table>
        <TablePagination
          component="div"
          count={filteredTourists.length}
          page={page}
          onPageChange={(_, nextPage) => setPage(nextPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(event) => { setRowsPerPage(Number(event.target.value)); setPage(0); }}
          rowsPerPageOptions={[10, 25, 50]}
          labelRowsPerPage="Строк на странице"
        />
      </TableContainer>

      <Dialog open={open} onClose={closeForm} maxWidth="md" fullWidth>
        <DialogTitle>{editingTourist ? 'Редактировать туриста' : 'Добавить туриста'}</DialogTitle>
        <DialogContent sx={{ pt: '16px !important' }}>
          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
          <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1 }}>Личные данные туриста</Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2, mb: 3 }}>
            <TextField label="Имя" value={form.tourist_name} onChange={(event) => setForm({ ...form, tourist_name: event.target.value })} sx={fieldStyles} required />
            <TextField label="Фамилия" value={form.tourist_surname} onChange={(event) => setForm({ ...form, tourist_surname: event.target.value })} sx={fieldStyles} required />
            <TextField label="Отчество" value={form.tourist_patronymic} onChange={(event) => setForm({ ...form, tourist_patronymic: event.target.value })} sx={fieldStyles} />
            <TextField type="date" label="Дата рождения" value={form.tourist_date_of_birth} onChange={(event) => setForm({ ...form, tourist_date_of_birth: event.target.value })} slotProps={{ inputLabel: { shrink: true } }} sx={fieldStyles} required />
            <TextField select label="Пол" value={form.tourist_gender} onChange={(event) => setForm({ ...form, tourist_gender: event.target.value })} sx={fieldStyles} required>
              <MenuItem value="Мужской">Мужской</MenuItem><MenuItem value="Женский">Женский</MenuItem>
            </TextField>
            <TextField select label="Категория" value={form.category} onChange={(event) => setForm({ ...form, category: event.target.value })} sx={fieldStyles} required>
              <MenuItem value="Отдых">Отдых</MenuItem><MenuItem value="Шоп-тур">Шоп-тур</MenuItem><MenuItem value="Ребенок">Ребенок</MenuItem>
            </TextField>
            <TextField select label="Есть дети" value={form.tourist_children} onChange={(event) => setForm({ ...form, tourist_children: event.target.value })} sx={fieldStyles}>
              <MenuItem value="Нет">Нет</MenuItem><MenuItem value="Да">Да</MenuItem>
            </TextField>
            <TextField select label="Сдает груз" value={form.tourist_cargo} onChange={(event) => setForm({ ...form, tourist_cargo: event.target.value })} sx={fieldStyles}>
              <MenuItem value="Нет">Нет</MenuItem><MenuItem value="Да">Да</MenuItem>
            </TextField>
            <TextField select label="Виза" value={form.has_visa ? 'true' : 'false'} onChange={(event) => setForm({ ...form, has_visa: event.target.value === 'true' })} sx={fieldStyles}>
              <MenuItem value="false">Не оформлена</MenuItem><MenuItem value="true">Оформлена</MenuItem>
            </TextField>
            <TextField type="number" label="ID рейса (необязательно)" value={form.flight_id} onChange={(event) => setForm({ ...form, flight_id: event.target.value })} sx={fieldStyles} />
          </Box>
          <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1 }}>Паспортные данные (необязательно)</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Если начали заполнять паспорт, заполните все поля. При редактировании пустые поля не удаляют сохраненные паспортные данные.
          </Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
            <TextField select label="Тип паспорта" value={passportForm.type_passport} onChange={(event) => setPassportForm({ ...passportForm, type_passport: event.target.value })} sx={fieldStyles}>
              <MenuItem value="Заграничный">Заграничный</MenuItem><MenuItem value="Внутренний">Внутренний</MenuItem>
            </TextField>
            <TextField label="Серия паспорта" value={passportForm.passport_serial} onChange={(event) => setPassportForm({ ...passportForm, passport_serial: event.target.value })} sx={fieldStyles} />
            <TextField label="Номер паспорта" value={passportForm.passport_number} onChange={(event) => setPassportForm({ ...passportForm, passport_number: event.target.value })} sx={fieldStyles} />
            <TextField label="Имя латиницей" value={passportForm.latin_name} onChange={(event) => setPassportForm({ ...passportForm, latin_name: event.target.value })} sx={fieldStyles} />
            <TextField type="date" label="Дата выдачи" value={passportForm.date_of_issue} onChange={(event) => setPassportForm({ ...passportForm, date_of_issue: event.target.value })} slotProps={{ inputLabel: { shrink: true } }} sx={fieldStyles} />
            <TextField type="date" label="Действителен до" value={passportForm.expiry_date} onChange={(event) => setPassportForm({ ...passportForm, expiry_date: event.target.value })} slotProps={{ inputLabel: { shrink: true } }} sx={fieldStyles} />
            <TextField label="Кем выдан" value={passportForm.issued_by} onChange={(event) => setPassportForm({ ...passportForm, issued_by: event.target.value })} sx={fieldStyles} />
            <TextField label="Код подразделения" value={passportForm.department_code} onChange={(event) => setPassportForm({ ...passportForm, department_code: event.target.value })} sx={fieldStyles} />
            <TextField label="Адрес регистрации" value={passportForm.registration_address} onChange={(event) => setPassportForm({ ...passportForm, registration_address: event.target.value })} sx={fieldStyles} />
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={closeForm}>Отмена</Button>
          <Button variant="contained" onClick={() => void saveTourist()} disabled={saving}>
            {saving ? <CircularProgress size={20} /> : 'Сохранить'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default TouristManagement;
