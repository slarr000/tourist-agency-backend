import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
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
import SearchIcon from '@mui/icons-material/Search';
import Inventory2OutlinedIcon from '@mui/icons-material/Inventory2Outlined';
import { apiRequest } from '../lib/api';

interface Tourist {
  tourist_id: number;
  tourist_name: string;
  tourist_surname: string;
  tourist_patronymic?: string | null;
  category: string;
}

interface Flight {
  flight_id: number;
  flight_number: string;
  flight_date: string;
  flight_type: string;
}

interface Cargo {
  cargo_id: number;
  tourist_id: number;
  cargo_type: string;
  places_count: number;
  actual_weight: number;
  volume_weight: number;
  marking: string;
  tags: string;
  packaging_cost: number;
  insurance_cost: number;
  total_amount: number;
  flight_id: number;
  status: string;
}

interface CargoForm {
  tourist_id: string;
  flight_id: string;
  cargo_type: string;
  places_count: string;
  actual_weight: string;
  volume_weight: string;
  marking: string;
  tags: string;
  packaging_cost: string;
  insurance_cost: string;
  status: string;
}

const cargoStatuses = ['Принят на склад', 'Упакован', 'Готов к отправке', 'Отправлен'];

const emptyForm: CargoForm = {
  tourist_id: '',
  flight_id: '',
  cargo_type: '',
  places_count: '1',
  actual_weight: '',
  volume_weight: '',
  marking: '',
  tags: '',
  packaging_cost: '0',
  insurance_cost: '0',
  status: 'Принят на склад',
};

const Warehouse = () => {
  const [cargo, setCargo] = useState<Cargo[]>([]);
  const [tourists, setTourists] = useState<Tourist[]>([]);
  const [flights, setFlights] = useState<Flight[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<Cargo | null>(null);
  const [form, setForm] = useState<CargoForm>(emptyForm);
  const [search, setSearch] = useState('');
  const [flightFilter, setFlightFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    try {
      const [cargoRows, touristRows, flightRows] = await Promise.all([
        apiRequest<Cargo[]>('/api/TouristCargo'),
        apiRequest<Tourist[]>('/api/Tourists'),
        apiRequest<Flight[]>('/api/Flights'),
      ]);
      setCargo(cargoRows);
      setTourists(touristRows);
      setFlights(flightRows);
      setError(null);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось загрузить складские ведомости.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let active = true;
    Promise.all([
      apiRequest<Cargo[]>('/api/TouristCargo'),
      apiRequest<Tourist[]>('/api/Tourists'),
      apiRequest<Flight[]>('/api/Flights'),
    ])
      .then(([cargoRows, touristRows, flightRows]) => {
        if (!active) return;
        setCargo(cargoRows);
        setTourists(touristRows);
        setFlights(flightRows);
        setError(null);
      })
      .catch((requestError: unknown) => {
        if (active) setError(requestError instanceof Error ? requestError.message : 'Не удалось загрузить складские ведомости.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, []);

  const touristNames = useMemo(() => new Map(
    tourists.map((tourist) => [
      tourist.tourist_id,
      [tourist.tourist_surname, tourist.tourist_name, tourist.tourist_patronymic].filter(Boolean).join(' '),
    ]),
  ), [tourists]);
  const flightNumbers = useMemo(() => new Map(
    flights.map((flight) => [flight.flight_id, `${flight.flight_number} · ${flight.flight_date.slice(0, 10)}`]),
  ), [flights]);

  const visibleCargo = cargo.filter((item) => {
    const touristName = touristNames.get(item.tourist_id) ?? '';
    const matchesText = `${touristName} ${item.cargo_type} ${item.tags} ${item.marking}`.toLocaleLowerCase()
      .includes(search.trim().toLocaleLowerCase());
    return matchesText
      && (!flightFilter || item.flight_id === Number(flightFilter))
      && (!statusFilter || item.status === statusFilter);
  });

  const totals = visibleCargo.reduce((sum, item) => ({
    places: sum.places + item.places_count,
    actualWeight: sum.actualWeight + item.actual_weight,
    volumeWeight: sum.volumeWeight + item.volume_weight,
    costs: sum.costs + item.total_amount,
  }), { places: 0, actualWeight: 0, volumeWeight: 0, costs: 0 });

  const startCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setError(null);
    setSuccess(null);
    setDialogOpen(true);
  };

  const startEdit = (item: Cargo) => {
    setEditing(item);
    setForm({
      tourist_id: String(item.tourist_id),
      flight_id: String(item.flight_id),
      cargo_type: item.cargo_type,
      places_count: String(item.places_count),
      actual_weight: String(item.actual_weight),
      volume_weight: String(item.volume_weight),
      marking: item.marking ?? '',
      tags: item.tags ?? '',
      packaging_cost: String(item.packaging_cost),
      insurance_cost: String(item.insurance_cost),
      status: item.status,
    });
    setError(null);
    setSuccess(null);
    setDialogOpen(true);
  };

  const save = async () => {
    if (!form.tourist_id || !form.flight_id || !form.cargo_type.trim()
      || Number(form.places_count) < 1 || Number(form.actual_weight) <= 0
      || Number(form.volume_weight) < 0 || Number(form.packaging_cost) < 0
      || Number(form.insurance_cost) < 0) {
      setError('Укажите туриста, рейс, вид груза, минимум одно место, фактический вес больше нуля и неотрицательные расходы.');
      return;
    }

    setSaving(true);
    setError(null);
    const packagingCost = Number(form.packaging_cost);
    const insuranceCost = Number(form.insurance_cost);
    const body = {
      ...form,
      tourist_id: Number(form.tourist_id),
      flight_id: Number(form.flight_id),
      cargo_type: form.cargo_type.trim(),
      places_count: Number(form.places_count),
      actual_weight: Number(form.actual_weight),
      volume_weight: Number(form.volume_weight),
      marking: form.marking.trim(),
      tags: form.tags.trim(),
      packaging_cost: packagingCost,
      insurance_cost: insuranceCost,
      total_amount: packagingCost + insuranceCost,
      status: form.status,
    };

    try {
      if (editing) {
        await apiRequest(`/api/TouristCargo/${editing.cargo_id}`, { method: 'PUT', body: JSON.stringify(body) });
      } else {
        await apiRequest('/api/TouristCargo', { method: 'POST', body: JSON.stringify(body) });
      }
      setDialogOpen(false);
      setSuccess(editing ? 'Весовая ведомость обновлена.' : 'Груз принят на склад и оформлен.');
      await loadData();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось сохранить весовую ведомость.');
    } finally {
      setSaving(false);
    }
  };

  const remove = async (item: Cargo) => {
    const name = touristNames.get(item.tourist_id) ?? `турист #${item.tourist_id}`;
    if (!window.confirm(`Удалить ведомость груза ${name} (${item.cargo_type})?`)) return;
    setError(null);
    try {
      await apiRequest(`/api/TouristCargo/${item.cargo_id}`, { method: 'DELETE' });
      setSuccess('Весовая ведомость удалена.');
      await loadData();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Не удалось удалить весовую ведомость.');
    }
  };

  const field = (key: keyof CargoForm, label: string, type = 'text', required = false) => (
    <TextField
      fullWidth
      required={required}
      type={type}
      label={label}
      value={form[key]}
      onChange={(event) => setForm({ ...form, [key]: event.target.value })}
      slotProps={type === 'date' ? { inputLabel: { shrink: true } } : undefined}
    />
  );

  return (
    <Box sx={{ maxWidth: 1400, mx: 'auto' }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: { xs: 'flex-start', sm: 'center' }, gap: 2, mb: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 800 }}>Склад и отправка груза</Typography>
          <Typography color="text.secondary" sx={{ mt: 0.5 }}>
            Прием, маркировка, взвешивание, упаковка и ведомости отправки по туристам и рейсам
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={startCreate}>Принять груз</Button>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {success && <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 2 }}>{success}</Alert>}

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr 1fr', lg: 'repeat(4, 1fr)' }, gap: 1.5, mb: 2 }}>
        {[
          { label: 'Грузовых ведомостей', value: visibleCargo.length },
          { label: 'Мест на складе / отправке', value: totals.places },
          { label: 'Фактический вес', value: `${totals.actualWeight.toFixed(1)} кг` },
          { label: 'Объемный вес', value: `${totals.volumeWeight.toFixed(1)} кг` },
        ].map((item) => (
          <Card key={item.label} variant="outlined">
            <CardContent sx={{ '&:last-child': { pb: 2 } }}>
              <Typography variant="caption" color="text.secondary">{item.label}</Typography>
              <Typography variant="h5" sx={{ fontWeight: 800, mt: 0.5 }}>{item.value}</Typography>
            </CardContent>
          </Card>
        ))}
      </Box>

      <Paper sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '2fr 1fr' }, gap: 1.5, p: 2, mb: 2 }}>
        <TextField
          size="small"
          label="Поиск по туристу, виду груза, бирке или маркировке"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          slotProps={{ input: { startAdornment: <SearchIcon fontSize="small" sx={{ mr: 1, color: 'text.secondary' }} /> } }}
        />
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 1.5 }}>
          <TextField select size="small" label="Рейс" value={flightFilter} onChange={(event) => setFlightFilter(event.target.value)}>
            <MenuItem value="">Все рейсы</MenuItem>
            {flights.map((flight) => (
              <MenuItem key={flight.flight_id} value={String(flight.flight_id)}>
                {flight.flight_number} · {flight.flight_date.slice(0, 10)}
              </MenuItem>
            ))}
          </TextField>
          <TextField select size="small" label="Этап обработки" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
            <MenuItem value="">Все этапы</MenuItem>
            {cargoStatuses.map((status) => <MenuItem key={status} value={status}>{status}</MenuItem>)}
          </TextField>
        </Box>
      </Paper>

      <TableContainer component={Paper}>
        <Table size="small">
          <TableHead>
            <TableRow>
              {['Турист', 'Категория', 'Рейс', 'Этап', 'Вид груза', 'Места', 'Вес факт. / объемный', 'Бирки и маркировка', 'Упаковка', 'Страховка', 'Итого'].map((label) => (
                <TableCell key={label} sx={{ fontWeight: 700, whiteSpace: 'nowrap' }}>{label}</TableCell>
              ))}
              <TableCell align="right">Действия</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow><TableCell colSpan={12} align="center"><CircularProgress size={24} /></TableCell></TableRow>
            ) : visibleCargo.length === 0 ? (
              <TableRow><TableCell colSpan={12} align="center" sx={{ py: 5, color: 'text.secondary' }}>Грузовые ведомости не найдены.</TableCell></TableRow>
            ) : visibleCargo.map((item) => (
              <TableRow hover key={item.cargo_id}>
                <TableCell>{touristNames.get(item.tourist_id) ?? `#${item.tourist_id}`}</TableCell>
                <TableCell>{tourists.find((tourist) => tourist.tourist_id === item.tourist_id)?.category ?? '—'}</TableCell>
                <TableCell>{flightNumbers.get(item.flight_id) ?? `#${item.flight_id}`}</TableCell>
                <TableCell>{item.status || 'Принят на склад'}</TableCell>
                <TableCell>{item.cargo_type}</TableCell>
                <TableCell>{item.places_count}</TableCell>
                <TableCell>{item.actual_weight} / {item.volume_weight} кг</TableCell>
                <TableCell>
                  {item.tags && <Typography variant="body2">Бирки: {item.tags}</Typography>}
                  {item.marking && <Typography variant="caption" color="text.secondary">Маркировка: {item.marking}</Typography>}
                  {!item.tags && !item.marking && '—'}
                </TableCell>
                <TableCell>{item.packaging_cost.toFixed(2)}</TableCell>
                <TableCell>{item.insurance_cost.toFixed(2)}</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>{item.total_amount.toFixed(2)}</TableCell>
                <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
                  <IconButton aria-label="Редактировать ведомость" onClick={() => startEdit(item)}><EditIcon /></IconButton>
                  <IconButton aria-label="Удалить ведомость" color="error" onClick={() => void remove(item)}><DeleteIcon /></IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {visibleCargo.length > 0 && (
        <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'right', mt: 1.5 }}>
          Итого по фильтру: фактический вес {totals.actualWeight.toFixed(1)} кг · объемный вес {totals.volumeWeight.toFixed(1)} кг · расходы на упаковку и страховку {totals.costs.toFixed(2)}
        </Typography>
      )}

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Inventory2OutlinedIcon color="primary" />
          {editing ? 'Изменить весовую / отправочную ведомость' : 'Прием груза на склад'}
        </DialogTitle>
        <DialogContent>
          <Typography color="text.secondary" variant="body2" sx={{ mb: 2 }}>
            Ведомость связывает владельца груза с рейсом. Итоговая сумма автоматически складывается из стоимости упаковки и страховки.
          </Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2, pt: 1 }}>
            <TextField select required label="Турист — владелец груза" value={form.tourist_id} onChange={(event) => setForm({ ...form, tourist_id: event.target.value })}>
              {tourists.filter((tourist) => tourist.category !== 'Ребенок').map((tourist) => (
                <MenuItem key={tourist.tourist_id} value={String(tourist.tourist_id)}>
                  #{tourist.tourist_id} · {[tourist.tourist_surname, tourist.tourist_name].join(' ')} · {tourist.category}
                </MenuItem>
              ))}
            </TextField>
            <TextField select required label="Рейс отправки" value={form.flight_id} onChange={(event) => setForm({ ...form, flight_id: event.target.value })}>
              {flights.map((flight) => (
                <MenuItem key={flight.flight_id} value={String(flight.flight_id)}>
                  {flight.flight_number} · {flight.flight_date.slice(0, 10)} · {flight.flight_type}
                </MenuItem>
              ))}
            </TextField>
            <TextField select required label="Этап обработки груза" value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value })}>
              {cargoStatuses.map((status) => <MenuItem key={status} value={status}>{status}</MenuItem>)}
            </TextField>
            {field('cargo_type', 'Вид груза', 'text', true)}
            {field('places_count', 'Количество мест', 'number', true)}
            {field('actual_weight', 'Фактический вес, кг', 'number', true)}
            {field('volume_weight', 'Объемный вес, кг', 'number', true)}
            {field('tags', 'Бирки / номера мест')}
            {field('marking', 'Маркировка груза')}
            {field('packaging_cost', 'Стоимость упаковки', 'number')}
            {field('insurance_cost', 'Стоимость страховки', 'number')}
            <TextField
              label="Итоговая сумма"
              value={(Number(form.packaging_cost || 0) + Number(form.insurance_cost || 0)).toFixed(2)}
              slotProps={{ input: { readOnly: true } }}
              helperText="Упаковка + страховка"
            />
          </Box>
          {error && <Alert severity="error" sx={{ mt: 2 }}>{error}</Alert>}
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setDialogOpen(false)}>Отмена</Button>
          <Button variant="contained" onClick={() => void save()} disabled={saving}>
            {saving ? <CircularProgress size={20} /> : 'Сохранить ведомость'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Warehouse;
