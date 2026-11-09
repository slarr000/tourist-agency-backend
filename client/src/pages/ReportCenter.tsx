import { useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  CircularProgress,
  LinearProgress,
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
import AssessmentIcon from '@mui/icons-material/Assessment';
import DownloadIcon from '@mui/icons-material/Download';
import { apiRequest } from '../lib/api';

type ReportParameters = 'category' | 'hotelName' | 'dates' | 'touristId' | 'flightNumber' | 'visa' | 'group' | 'month';

interface ReportDefinition {
  id: string;
  title: string;
  endpoint: string;
  parameters?: ReportParameters[];
}

const reports: ReportDefinition[] = [
  { id: 'customs', title: '1. Список туристов для таможни', endpoint: '/api/Reports/customs-list', parameters: ['category'] },
  { id: 'check-in', title: '2. Списки на расселение', endpoint: '/api/Reports/hotel-check-in-list', parameters: ['hotelName', 'category'] },
  { id: 'tourist-count', title: '3. Количество туристов за период', endpoint: '/api/Reports/tourists-count', parameters: ['dates', 'category'] },
  { id: 'tourist-profile', title: '4. История туриста', endpoint: '/api/Reports/tourist-profile', parameters: ['touristId'] },
  { id: 'hotel-occupancy', title: '5. Загрузка гостиниц', endpoint: '/api/Reports/hotel-occupancy', parameters: ['dates', 'category'] },
  { id: 'excursion-count', title: '6. Участники экскурсий за период', endpoint: '/api/Reports/excursions-tourists-count', parameters: ['dates'] },
  { id: 'excursions', title: '7. Популярность экскурсий', endpoint: '/api/Reports/excursions-summary' },
  { id: 'agency-quality', title: '7. Рейтинг качества экскурсионных агентств', endpoint: '/api/Reports/excursion-agency-quality' },
  { id: 'flight-load', title: '8. Загрузка рейсов', endpoint: '/api/Reports/flight-load', parameters: ['dates', 'flightNumber'] },
  { id: 'cargo-summary', title: '9. Грузооборот склада', endpoint: '/api/Reports/cargo-turnover', parameters: ['dates'] },
  { id: 'financial', title: '10. Финансовый отчет по группе и категории', endpoint: '/api/Reports/financial-summary', parameters: ['dates', 'group', 'category'] },
  { id: 'financial-items', title: '11. Доходы и расходы по статьям', endpoint: '/api/Reports/financial-items', parameters: ['dates', 'group', 'category'] },
  { id: 'cargo-statistics', title: '12. Статистика по видам груза', endpoint: '/api/Reports/cargo-statistics', parameters: ['dates'] },
  { id: 'profitability', title: '13. Рентабельность представительства', endpoint: '/api/Reports/financial-summary', parameters: ['dates', 'group', 'category'] },
  { id: 'category-ratio', title: '14. Соотношение категорий туристов', endpoint: '/api/Reports/category-ratio', parameters: ['dates'] },
  { id: 'flight-details', title: '15. Туристы, груз и маркировка по рейсу', endpoint: '/api/Reports/flight-tourist-details', parameters: ['flightNumber'] },
  { id: 'passport-control', title: 'Контроль срока действия паспортов', endpoint: '/api/Reports/passport-control' },
  { id: 'family-tours', title: 'Список детей и сопровождающих', endpoint: '/api/Reports/family-tours' },
  { id: 'visa-status', title: 'Статус оформления виз', endpoint: '/api/Reports/visa-status', parameters: ['visa'] },
  { id: 'monthly-business', title: 'Ежемесячный отчет о работе фирмы', endpoint: '/api/Reports/monthly-business', parameters: ['month'] },
];

const reportColumnLabels: Record<string, string> = {
  actualWeight: 'Фактический вес',
  agencyName: 'Экскурсионное агентство',
  agencyId: 'ID экскурсионного агентства',
  agencyQuality: 'Оценка агентства',
  agencyRating: 'Оценка агентства',
  adultCount: 'Количество взрослых',
  adultTourists: 'Взрослые сопровождающие',
  accompanyingChildren: 'Сопровождающие дети',
  amount: 'Сумма',
  arrivalDate: 'Дата прилета',
  arrivalDateTime: 'Дата и время прилета',
  availableSeats: 'Свободные места',
  baggageCount: 'Количество мест багажа',
  baggageWeight: 'Вес багажа',
  bookedParticipants: 'Записано участников',
  bookingCount: 'Количество бронирований',
  bookingDate: 'Дата бронирования',
  bookingStatus: 'Статус бронирования',
  cargoCount: 'Количество грузовых мест',
  cargoOnlyFlights: 'Грузовые рейсы',
  cargoPlaces: 'Грузовые места',
  cargoType: 'Вид груза',
  cargoWeight: 'Вес груза',
  category: 'Категория туриста',
  categoryName: 'Категория туриста',
  checkInDate: 'Дата заселения',
  checkOutDate: 'Дата выселения',
  childAge: 'Возраст ребенка',
  childDocumentsProcessed: 'Оформлено детских документов',
  childName: 'Имя ребенка',
  children: 'Дети',
  childrenCount: 'Количество детей',
  childrenNames: 'Имена детей',
  cost: 'Стоимость',
  country: 'Страна',
  departureDate: 'Дата вылета',
  departureDateTime: 'Дата и время вылета',
  destination: 'Пункт назначения',
  daysUntilExpiration: 'Дней до окончания срока',
  documentCount: 'Количество документов',
  documentStatus: 'Статус оформления документа',
  expense: 'Расходы',
  expenseAmount: 'Сумма расходов',
  expenseCategory: 'Статья расходов',
  expenseCount: 'Количество расходов',
  expirationDate: 'Срок действия до',
  flightDate: 'Дата рейса',
  flightId: 'ID рейса',
  flightNumber: 'Номер рейса',
  flightType: 'Тип рейса',
  flightsWithCargo: 'Рейсы с грузом',
  excursionCount: 'Количество экскурсий',
  excursionAgency: 'Экскурсионное агентство',
  excursionAgencyName: 'Экскурсионное агентство',
  excursionDate: 'Дата экскурсии',
  excursionHistory: 'История экскурсий',
  excursionId: 'ID экскурсии',
  excursionName: 'Экскурсия',
  excursionTitle: 'Экскурсия',
  gender: 'Пол',
  groupId: 'ID группы',
  hasVisa: 'Виза оформлена',
  holidayCount: 'Отдыхающие туристы',
  holidayPercentage: 'Доля отдыхающих, %',
  hotel: 'Гостиница',
  hotelHistory: 'История проживания',
  hotelId: 'ID гостиницы',
  hotelName: 'Гостиница',
  hotelCount: 'Количество гостиниц',
  hotelRevenue: 'Доход гостиниц',
  income: 'Доходы',
  incomeAmount: 'Сумма доходов',
  incomeCategory: 'Статья доходов',
  netProfit: 'Прибыль',
  issuedPassports: 'Оформлено паспортов',
  marking: 'Маркировка',
  luggageWeight: 'Вес багажа',
  luggageVolume: 'Объем багажа',
  month: 'Месяц',
  mostDemandedPackages: 'Наиболее востребованные путевки',
  name: 'Наименование',
  netIncome: 'Чистая прибыль',
  numberOfSeats: 'Количество мест',
  occupiedRooms: 'Занято номеров',
  occupancy: 'Заполняемость',
  occupancyRate: 'Заполняемость',
  passengerCargoFlights: 'Грузопассажирские рейсы',
  passengerCount: 'Количество пассажиров',
  passengerWeight: 'Вес багажа пассажиров',
  passportExpiryDate: 'Срок действия паспорта',
  passportNumber: 'Номер паспорта',
  percentage: 'Доля, %',
  packagesWithoutSales: 'Путевки без продаж',
  parentFullName: 'ФИО сопровождающего',
  parentName: 'Сопровождающий',
  passengerCapacity: 'Вместимость самолета',
  passengers: 'Пассажиры',
  placesCount: 'Количество мест',
  price: 'Стоимость',
  profit: 'Прибыль',
  profitAmount: 'Сумма прибыли',
  profitMargin: 'Рентабельность',
  profitability: 'Рентабельность',
  profitabilityPercent: 'Рентабельность, %',
  quantity: 'Количество',
  qualityRank: 'Место в рейтинге',
  qualityRating: 'Оценка качества',
  rank: 'Место в рейтинге',
  rating: 'Оценка',
  residentChildren: 'Проживающие дети',
  residentTourists: 'Проживающие туристы',
  revenue: 'Выручка',
  revenueAmount: 'Сумма доходов',
  roomCount: 'Количество номеров',
  roomNumber: 'Номер комнаты',
  roomsCount: 'Количество номеров',
  seatCapacity: 'Вместимость самолета',
  seats: 'Количество мест',
  scheduleDate: 'Дата экскурсии',
  shopTourCount: 'Туристы шоп-туров',
  shopTourPercentage: 'Доля туристов шоп-туров, %',
  totalExpenses: 'Общие расходы за месяц',
  totalDocuments: 'Всего оформлено документов',
  totalExpense: 'Общие расходы',
  totalActualWeight: 'Общий фактический вес',
  totalInsuranceCost: 'Общая стоимость страховки',
  totalIncome: 'Общий доход',
  totalRevenue: 'Общая выручка по финансовым операциям',
  totalTourists: 'Всего участников',
  totalResidents: 'Всего проживающих',
  totalVolumeWeight: 'Общий объемный вес',
  totalPlaces: 'Всего грузовых мест',
  totalVisits: 'Количество поездок',
  totalWeight: 'Общий вес',
  transactionCount: 'Количество операций',
  transactionType: 'Тип операции',
  touristCount: 'Количество туристов',
  touristId: 'ID туриста',
  touristFullName: 'ФИО туриста-сопровождающего',
  touristName: 'ФИО туриста',
  touristType: 'Категория туриста',
  tourName: 'Название тура',
  tags: 'Бирки груза',
  type: 'Тип',
  visaStatus: 'Статус визы',
  visaCount: 'Количество виз',
  visitHistory: 'История поездок',
  voucherName: 'Путевка',
  volumeWeight: 'Объемный вес',
  soldVouchers: 'Продано путевок',
  visasProcessed: 'Оформлено виз',
  voucherRevenue: 'Выручка от проданных путевок',
  weight: 'Вес',
  year: 'Год',
  fullName: 'ФИО туриста',
};

const normalizeKey = (key: string) => key.replace(/[_\-\s]+(.)?/g, (_, letter: string | undefined) => letter?.toUpperCase() ?? '').replace(/^./, (letter) => letter.toLowerCase());
const labelForKey = (key: string) => reportColumnLabels[normalizeKey(key)] ?? key.replace(/([a-z0-9])([A-Z])/g, '$1 $2').replace(/[_-]/g, ' ').replace(/^./, (letter) => letter.toUpperCase());

const numericValue = (value: unknown): number | null => {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '' && Number.isFinite(Number(value))) return Number(value);
  return null;
};

const formatNumber = (value: number) => new Intl.NumberFormat('ru-RU', { maximumFractionDigits: 2 }).format(value);
const recordWord = (count: number) => {
  const remainder100 = count % 100;
  if (remainder100 >= 11 && remainder100 <= 14) return 'записей';
  const remainder10 = count % 10;
  if (remainder10 === 1) return 'запись';
  if (remainder10 >= 2 && remainder10 <= 4) return 'записи';
  return 'записей';
};

const formatCell = (value: unknown) => {
  if (value == null || value === '') return '—';
  if (Array.isArray(value)) return value.map((item) => typeof item === 'object' && item !== null ? JSON.stringify(item) : String(item)).join('; ') || '—';
  if (typeof value === 'object') return JSON.stringify(value);
  if (typeof value === 'number') return formatNumber(value);
  return String(value);
};

const formatReportCell = (value: unknown, key: string) => {
  if (typeof value === 'boolean') return key.toLowerCase().includes('visa') ? (value ? 'Оформлена' : 'Не оформлена') : (value ? 'Да' : 'Нет');
  if (typeof value === 'string' && /(date|expiration)/i.test(key) && /^\d{4}-\d{2}-\d{2}/.test(value)) {
    const [year, month, day] = value.slice(0, 10).split('-').map(Number);
    const date = value.includes('T') ? new Date(value) : new Date(year, month - 1, day);
    if (Number.isNaN(date.getTime())) return value;
    const options: Intl.DateTimeFormatOptions = value.includes('T') && !/T00:00:00/.test(value)
      ? { dateStyle: 'medium', timeStyle: 'short' }
      : { dateStyle: 'medium' };
    return new Intl.DateTimeFormat('ru-RU', options).format(date);
  }
  return formatCell(value);
};

const metricKeys = /(count|total|weight|revenue|income|expense|profit|cost|price|amount|tourists|participants|passengers|seats|places|rooms|documents|vouchers|visas|passports|rating|quality|percentage|share|percent|quantity|number|occupancy)/i;
const currencyKeys = /(revenue|income|expense|profit|cost|price|amount|financial)/i;
const metricPriority = (key: string) => {
  if (/profit/i.test(key)) return 6;
  if (/total.*(revenue|income)|(revenue|income).*total/i.test(key)) return 5;
  if (/expense|cost/i.test(key)) return 4;
  if (/revenue|income/i.test(key)) return 3;
  if (/participants|tourists|passengers/i.test(key)) return 2;
  if (/count|weight|quantity|places|rooms|documents|vouchers|visas|passports/i.test(key)) return 1;
  return 0;
};

const ReportCenter = () => {
  const [reportId, setReportId] = useState(reports[0].id);
  const [category, setCategory] = useState('');
  const [hotelName, setHotelName] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [touristId, setTouristId] = useState('');
  const [flightNumber, setFlightNumber] = useState('');
  const [month, setMonth] = useState('');
  const [flightId, setFlightId] = useState('');
  const [hasVisa, setHasVisa] = useState('true');
  const [rows, setRows] = useState<Record<string, unknown>[]>([]);
  const [hasRun, setHasRun] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const selectedReport = reports.find((report) => report.id === reportId) ?? reports[0];
  const columns = useMemo(() => [...new Set(rows.flatMap((row) => Object.keys(row)))], [rows]);
  const summaryMetrics = useMemo(() => columns
    .filter((column) => metricKeys.test(column) && !/(^id$|id$|year|month|rank)/i.test(column))
    .sort((left, right) => metricPriority(right) - metricPriority(left))
    .map((column) => {
      const values = rows.map((row) => numericValue(row[column])).filter((value): value is number => value !== null);
      if (values.length === 0) return null;
      const isAverage = /(rating|quality|percentage|share|percent|margin|rate|occupancy)/i.test(column);
      const value = isAverage
        ? values.reduce((total, current) => total + current, 0) / values.length
        : values.reduce((total, current) => total + current, 0);
      const isCurrency = currencyKeys.test(column);
      const isPercent = /(percentage|share|percent|margin|rate|occupancy)/i.test(column);
      return {
        key: column,
        label: labelForKey(column),
        value: `${formatNumber(value)}${isCurrency ? ' ₽' : isPercent ? '%' : ''}`,
        tone: /(expense|cost)/i.test(column) ? 'warning' : /(profit|revenue|income)/i.test(column) ? 'success' : 'primary',
      };
    })
    .filter((metric): metric is NonNullable<typeof metric> => metric !== null)
    .slice(0, 3), [columns, rows]);

  const chartData = useMemo(() => {
    if (rows.length === 1) {
      const percentages = columns
        .filter((column) => /(percentage|percent|share)/i.test(column))
        .map((column) => ({ label: labelForKey(column), value: numericValue(rows[0][column]) }))
        .filter((item): item is { label: string; value: number } => item.value !== null);
      if (percentages.length > 1) return { label: 'Распределение, %', values: percentages, max: 100 };
    }
    if (rows.length < 2 || rows.length > 8) return null;
    const metricColumn = columns.find((column) => metricKeys.test(column) && !/(^id$|id$|year|month|rank)/i.test(column));
    const labelColumn = columns.find((column) => rows.some((row) => typeof row[column] === 'string' && numericValue(row[column]) === null));
    if (!metricColumn || !labelColumn) return null;
    const values = rows.map((row) => ({ label: formatCell(row[labelColumn]), value: numericValue(row[metricColumn]) }))
      .filter((item): item is { label: string; value: number } => item.value !== null);
    if (values.length < 2) return null;
    const max = Math.max(...values.map((item) => Math.abs(item.value)), 1);
    return { label: labelForKey(metricColumn), values, max };
  }, [columns, rows]);

  const runReport = async () => {
    setError(null);
    if (selectedReport.parameters?.includes('dates')) {
      if (!startDate || !endDate) {
        setError('Укажите начало и конец периода.');
        return;
      }
      if (startDate > endDate) {
        setError('Начало периода не может быть позже его окончания.');
        return;
      }
    }

    if (selectedReport.parameters?.includes('touristId') && (!Number.isInteger(Number(touristId)) || Number(touristId) < 1)) {
      setError('Введите корректный ID туриста.');
      return;
    }
    if (selectedReport.parameters?.includes('flightNumber') && !flightNumber.trim()) {
      if (selectedReport.id === 'flight-details') {
        setError('Введите номер рейса.');
        return;
      }
    }
    if (selectedReport.parameters?.includes('month') && !month) {
      setError('Выберите отчетный месяц.');
      return;
    }
    if (selectedReport.parameters?.includes('group') && flightId && (!Number.isInteger(Number(flightId)) || Number(flightId) < 1)) {
      setError('Введите корректный ID группы (рейса).');
      return;
    }

    const query = new URLSearchParams();
    if (selectedReport.parameters?.includes('category') && category) query.set('category', category);
    if (selectedReport.parameters?.includes('hotelName') && hotelName.trim()) query.set('hotelName', hotelName.trim());
    if (selectedReport.parameters?.includes('dates')) {
      query.set('startDate', startDate);
      query.set('endDate', endDate);
    }
    if (selectedReport.parameters?.includes('flightNumber')) query.set('flightNumber', flightNumber.trim());
    if (selectedReport.parameters?.includes('visa')) query.set('hasVisa', hasVisa);
    if (selectedReport.parameters?.includes('group') && flightId) query.set('flightId', flightId);
    if (selectedReport.parameters?.includes('month') && month) {
      const [year, selectedMonth] = month.split('-');
      query.set('year', year);
      query.set('month', selectedMonth);
    }

    const endpoint = selectedReport.parameters?.includes('touristId')
      ? `${selectedReport.endpoint}/${encodeURIComponent(touristId)}`
      : selectedReport.endpoint;
    const url = query.size ? `${endpoint}?${query.toString()}` : endpoint;

    setLoading(true);
    setHasRun(true);
    try {
      const result = await apiRequest<unknown>(url);
      const resultRows: Record<string, unknown>[] = Array.isArray(result)
        ? result as Record<string, unknown>[]
        : result && typeof result === 'object'
          ? [result as Record<string, unknown>]
          : [];
      setRows(resultRows);
    } catch (requestError) {
      setRows([]);
      setError(requestError instanceof Error ? requestError.message : 'Не удалось получить отчет.');
    } finally {
      setLoading(false);
    }
  };

  const exportCsv = () => {
    if (rows.length === 0 || columns.length === 0) return;
    const escapeCell = (value: unknown) => `"${formatCell(value).replace(/"/g, '""')}"`;
    const csv = [
      columns.map(escapeCell).join(';'),
      ...rows.map((row) => columns.map((column) => escapeCell(row[column])).join(';')),
    ].join('\r\n');
    const url = URL.createObjectURL(new Blob(['\uFEFF', csv], { type: 'text/csv;charset=utf-8' }));
    const link = document.createElement('a');
    link.href = url;
    link.download = `${reportId}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  };

  const fieldStyles = {
    minWidth: { xs: '100%', sm: 220 },
    '& .MuiInputLabel-root': { color: 'var(--color-muted)' },
    '& .MuiOutlinedInput-root': {
      color: 'var(--color-text)',
      borderRadius: 2,
      backgroundColor: 'var(--color-bg-soft)',
      '& fieldset': { borderColor: 'var(--color-line)' },
      '&:hover fieldset': { borderColor: 'var(--color-teal)' },
    },
  };

  return (
    <Box sx={{ maxWidth: 1440, mx: 'auto', pb: 4 }}>
      <Paper
        elevation={0}
        sx={{
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          gap: 2,
          p: { xs: 2.5, sm: 3.5 },
          mb: 3,
          border: '1px solid var(--color-line)',
          borderRadius: 4,
          background: 'linear-gradient(120deg, var(--color-surface-solid), var(--color-bg-soft))',
          '&::after': {
            position: 'absolute',
            width: 220,
            height: 220,
            right: -60,
            top: -110,
            borderRadius: '50%',
            background: 'var(--glow-teal)',
            content: '""',
            pointerEvents: 'none',
          },
        }}
      >
        <Box sx={{ display: 'grid', placeItems: 'center', flexShrink: 0, width: 56, height: 56, borderRadius: 3, color: 'var(--color-teal)', backgroundColor: 'var(--color-bg-soft)', border: '1px solid var(--color-line)' }}>
          <AssessmentIcon sx={{ fontSize: 30 }} />
        </Box>
        <Box sx={{ position: 'relative', zIndex: 1 }}>
          <Typography variant="h4" sx={{ color: 'var(--color-text)', fontWeight: 800, letterSpacing: '-0.04em', fontSize: { xs: '1.7rem', sm: '2.1rem' } }}>Центр отчетов</Typography>
          <Typography sx={{ mt: 0.4, color: 'var(--color-muted)' }}>Аналитика представительства · вариант №10</Typography>
        </Box>
      </Paper>

      <Paper elevation={0} sx={{ p: { xs: 2, sm: 2.5 }, mb: 3, borderRadius: 3, backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-line)', boxShadow: 'var(--shadow-card)' }}>
        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1.5, alignItems: 'center' }}>
          <TextField select label="Отчет" value={reportId} onChange={(event) => { setReportId(event.target.value); setRows([]); setHasRun(false); setError(null); }} sx={{ ...fieldStyles, flex: '1 1 300px' }}>
            {reports.map((report) => <MenuItem key={report.id} value={report.id}>{report.title}</MenuItem>)}
          </TextField>

          {selectedReport.parameters?.includes('category') && (
            <TextField select label="Категория" value={category} onChange={(event) => setCategory(event.target.value)} sx={fieldStyles}>
              <MenuItem value="">Все категории</MenuItem>
              <MenuItem value="Отдых">Отдых</MenuItem>
              <MenuItem value="Шоп-тур">Шоп-тур</MenuItem>
            </TextField>
          )}
          {selectedReport.parameters?.includes('hotelName') && (
            <TextField label="Гостиница (необязательно)" value={hotelName} onChange={(event) => setHotelName(event.target.value)} sx={fieldStyles} />
          )}
          {selectedReport.parameters?.includes('dates') && (
            <>
              <TextField type="date" label="С даты" value={startDate} onChange={(event) => setStartDate(event.target.value)} slotProps={{ inputLabel: { shrink: true } }} sx={fieldStyles} />
              <TextField type="date" label="По дату" value={endDate} onChange={(event) => setEndDate(event.target.value)} slotProps={{ inputLabel: { shrink: true } }} sx={fieldStyles} />
            </>
          )}
          {selectedReport.parameters?.includes('touristId') && (
            <TextField type="number" label="ID туриста" value={touristId} onChange={(event) => setTouristId(event.target.value)} sx={fieldStyles} />
          )}
          {selectedReport.parameters?.includes('flightNumber') && (
            <TextField label={selectedReport.id === 'flight-details' ? 'Номер рейса' : 'Номер рейса (опционально)'} value={flightNumber} onChange={(event) => setFlightNumber(event.target.value)} sx={fieldStyles} />
          )}
          {selectedReport.parameters?.includes('group') && (
            <TextField type="number" label="ID группы / рейса (опционально)" value={flightId} onChange={(event) => setFlightId(event.target.value)} sx={fieldStyles} />
          )}
          {selectedReport.parameters?.includes('month') && (
            <TextField type="month" label="Отчетный месяц" value={month} onChange={(event) => setMonth(event.target.value)} slotProps={{ inputLabel: { shrink: true } }} sx={fieldStyles} />
          )}
          {selectedReport.parameters?.includes('visa') && (
            <TextField select label="Статус визы" value={hasVisa} onChange={(event) => setHasVisa(event.target.value)} sx={fieldStyles}>
              <MenuItem value="true">Оформлена</MenuItem>
              <MenuItem value="false">Не оформлена</MenuItem>
            </TextField>
          )}

          <Button className="soft-button" variant="contained" onClick={runReport} disabled={loading} sx={{ minHeight: 56, px: 3, borderRadius: 2, backgroundColor: 'var(--color-teal)', color: 'var(--color-bg)', fontWeight: 800, '&:hover': { backgroundColor: 'var(--color-teal-deep)' } }}>
            {loading ? <CircularProgress size={22} sx={{ color: 'inherit' }} /> : 'Сформировать'}
          </Button>
          <Button className="soft-button" variant="outlined" startIcon={<DownloadIcon />} onClick={exportCsv} disabled={rows.length === 0} sx={{ minHeight: 56, px: 2.5, borderRadius: 2, color: 'var(--color-text)', borderColor: 'var(--color-line)' }}>
            CSV
          </Button>
        </Box>
      </Paper>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {loading && <LinearProgress sx={{ mb: 2, borderRadius: 4, backgroundColor: 'var(--color-bg-soft)', '& .MuiLinearProgress-bar': { backgroundColor: 'var(--color-teal)' } }} />}
      {hasRun && !loading && !error && rows.length === 0 && (
        <Paper elevation={0} sx={{ p: 4, textAlign: 'center', borderRadius: 3, border: '1px dashed var(--color-line)', backgroundColor: 'var(--color-surface)' }}>
          <Typography variant="h6" sx={{ color: 'var(--color-text)', fontWeight: 700 }}>Нет данных для отображения</Typography>
          <Typography sx={{ mt: 0.5, color: 'var(--color-muted)' }}>Попробуйте изменить период или параметры отчета.</Typography>
        </Paper>
      )}

      {rows.length > 0 && (
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2, mb: 1.5, flexWrap: 'wrap' }}>
            <Box>
              <Typography variant="h5" sx={{ color: 'var(--color-text)', fontWeight: 800 }}>{selectedReport.title.replace(/^\d+\.\s*/, '')}</Typography>
              <Typography variant="body2" sx={{ color: 'var(--color-muted)', mt: 0.4 }}>Результаты сформированного отчета</Typography>
            </Box>
            <Chip
              label={`${formatNumber(rows.length)} ${recordWord(rows.length)}`}
              sx={{ color: 'var(--color-teal)', backgroundColor: 'var(--color-surface-solid)', border: '1px solid var(--color-line)', fontWeight: 700 }}
            />
          </Box>

          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(auto-fit, minmax(190px, 1fr))' }, gap: 1.5, mb: chartData ? 2 : 2.5 }}>
            {summaryMetrics.map((metric, index) => (
              <Paper
                key={metric.key}
                elevation={0}
                sx={{
                  position: 'relative',
                  overflow: 'hidden',
                  p: 2.25,
                  borderRadius: 3,
                  border: '1px solid var(--color-line)',
                  background: 'linear-gradient(140deg, var(--color-surface-solid), var(--color-surface))',
                  animation: `reveal 420ms ease both`,
                  animationDelay: `${index * 70}ms`,
                  '&::before': {
                    position: 'absolute',
                    inset: '0 auto 0 0',
                    width: 4,
                    backgroundColor: metric.tone === 'warning' ? '#e5a84b' : metric.tone === 'success' ? '#34b38a' : 'var(--color-teal)',
                    content: '""',
                  },
                }}
              >
                <Typography variant="body2" sx={{ color: 'var(--color-muted)', fontWeight: 600, minHeight: 38 }}>{metric.label}</Typography>
                <Typography variant="h5" sx={{ mt: 0.5, color: 'var(--color-text)', fontWeight: 800, overflowWrap: 'anywhere' }}>{metric.value}</Typography>
              </Paper>
            ))}
            <Paper elevation={0} sx={{ p: 2.25, borderRadius: 3, border: '1px solid var(--color-line)', background: 'linear-gradient(140deg, var(--color-surface-solid), var(--color-surface))' }}>
              <Typography variant="body2" sx={{ color: 'var(--color-muted)', fontWeight: 600 }}>Строк в отчете</Typography>
              <Typography variant="h5" sx={{ mt: 0.5, color: 'var(--color-text)', fontWeight: 800 }}>{formatNumber(rows.length)}</Typography>
            </Paper>
          </Box>

          {chartData && (
            <Paper elevation={0} sx={{ p: { xs: 2, sm: 2.5 }, mb: 2.5, borderRadius: 3, border: '1px solid var(--color-line)', backgroundColor: 'var(--color-surface)' }}>
              <Typography variant="subtitle1" sx={{ mb: 2, color: 'var(--color-text)', fontWeight: 800 }}>{chartData.label} · сравнение</Typography>
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, minmax(0, 1fr))' }, gap: 1.5 }}>
                {chartData.values.map((item, index) => (
                  <Box key={`${item.label}-${index}`} sx={{ minWidth: 0 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', gap: 1, mb: 0.6 }}>
                      <Typography variant="body2" sx={{ color: 'var(--color-text)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.label}</Typography>
                      <Typography variant="body2" sx={{ color: 'var(--color-muted)', fontWeight: 700 }}>{formatNumber(item.value)}</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={Math.max(0, Math.min(100, Math.abs(item.value) / chartData.max * 100))} sx={{ height: 7, borderRadius: 8, backgroundColor: 'var(--color-bg-soft)', '& .MuiLinearProgress-bar': { borderRadius: 8, background: 'linear-gradient(90deg, var(--color-teal-deep), var(--color-teal))' } }} />
                  </Box>
                ))}
              </Box>
            </Paper>
          )}

          <TableContainer component={Paper} elevation={0} sx={{ maxHeight: 660, borderRadius: 3, border: '1px solid var(--color-line)', backgroundColor: 'var(--color-surface)', boxShadow: 'var(--shadow-card)' }}>
            <Table stickyHeader size="small" sx={{ minWidth: 720 }}>
              <TableHead>
                <TableRow>
                  {columns.map((column) => (
                    <TableCell key={column} sx={{ minWidth: 140, color: 'var(--color-teal)', fontWeight: 800, backgroundColor: 'var(--color-surface-solid)', borderBottom: '1px solid var(--color-line)', whiteSpace: 'nowrap' }}>
                      {labelForKey(column)}
                    </TableCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((row, index) => (
                  <TableRow key={index} hover sx={{
                    '&:nth-of-type(even)': { backgroundColor: 'var(--color-bg-soft)' },
                    '&:hover': { backgroundColor: 'var(--glow-teal) !important' },
                    '& td': { borderBottom: '1px solid var(--color-line)' },
                  }}>
                    {columns.map((column) => (
                      <TableCell key={column} sx={{ color: 'var(--color-text)', whiteSpace: 'pre-wrap', overflowWrap: 'anywhere', verticalAlign: 'top', maxWidth: 360 }}>
                        {formatReportCell(/^(year|month)$/i.test(normalizeKey(column)) && row[column] != null ? String(row[column]) : row[column], column)}
                      </TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Box>
      )}
    </Box>
  );
};

export default ReportCenter;
