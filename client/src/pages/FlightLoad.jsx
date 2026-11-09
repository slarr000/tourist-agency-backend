import { useState, useEffect } from 'react';
import {
    Box, Typography, Paper, Table, TableBody, TableCell,
    TableContainer, TableHead, TableRow, Button, CircularProgress, LinearProgress
} from '@mui/material';
import FlightTakeoffIcon from '@mui/icons-material/FlightTakeoff';
import DownloadIcon from '@mui/icons-material/Download';

function FlightLoad() {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        setTimeout(() => {
            setData([
                { id: 'SU-100', destination: 'Анталья, Турция', date: '2026-11-10', booked: 145, capacity: 150 },
                { id: 'B2-984', destination: 'Минск, Беларусь', date: '2026-11-12', booked: 45, capacity: 100 },
                { id: 'FZ-201', destination: 'Дубай, ОАЭ', date: '2026-11-15', booked: 110, capacity: 120 },
            ]);
            setLoading(false);
        }, 800);
    }, []);

    return (
        <Box sx={{ maxWidth: '1200px', margin: '0 auto', animation: 'fadeIn 0.5s ease-in-out' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', mb: 4 }}>
                <Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1 }}>
                        <Box sx={{ p: 1, borderRadius: '10px', backgroundColor: 'rgba(97, 218, 251, 0.1)', border: '1px solid rgba(97, 218, 251, 0.2)' }}>
                            <FlightTakeoffIcon sx={{ color: '#61dafb', fontSize: 24, display: 'block' }} />
                        </Box>
                        <Typography variant="h4" sx={{ fontWeight: 800, color: '#fff', letterSpacing: '-0.5px' }}>
                            Загрузка рейсов
                        </Typography>
                    </Box>
                    <Typography variant="body1" sx={{ color: '#888', ml: 7 }}>
                        Аналитика заполняемости чартерных и регулярных рейсов
                    </Typography>
                </Box>
                <Button variant="outlined" startIcon={<DownloadIcon />} sx={{ color: '#61dafb', borderColor: 'rgba(97, 218, 251, 0.3)', borderRadius: '12px', textTransform: 'none', fontWeight: 600, '&:hover': { borderColor: '#61dafb', backgroundColor: 'rgba(97, 218, 251, 0.1)' } }}>
                    Экспорт PDF
                </Button>
            </Box>

            <TableContainer component={Paper} sx={{ backgroundColor: 'rgba(18, 18, 18, 0.4)', backdropFilter: 'blur(12px)', borderRadius: '16px', border: '1px solid rgba(255, 255, 255, 0.05)', boxShadow: '0 8px 32px rgba(0,0,0,0.2)' }}>
                <Table>
                    <TableHead sx={{ backgroundColor: 'rgba(255, 255, 255, 0.02)' }}>
                        <TableRow>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Номер рейса</TableCell>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Направление</TableCell>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>Дата вылета</TableCell>
                            <TableCell sx={{ color: '#666', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', borderBottom: '1px solid rgba(255,255,255,0.05)', width: '30%' }}>Заполняемость</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow><TableCell colSpan={4} align="center" sx={{ py: 10, borderBottom: 'none' }}><CircularProgress sx={{ color: '#61dafb' }} /></TableCell></TableRow>
                        ) : (
                            data.map((row) => {
                                const loadPercentage = Math.round((row.booked / row.capacity) * 100);
                                // Логика цвета: до 70% зеленый, до 90% желтый, выше 90% красный
                                const barColor = loadPercentage >= 95 ? '#f44336' : loadPercentage >= 80 ? '#ffb74d' : '#4caf50';

                                return (
                                    <TableRow key={row.id} sx={{ '&:hover': { backgroundColor: 'rgba(255, 255, 255, 0.03)' }, '& td': { borderBottom: '1px solid rgba(255,255,255,0.03)', py: 2.5 } }}>
                                        <TableCell sx={{ color: '#61dafb !important', fontWeight: 700, fontFamily: 'monospace', fontSize: '15px' }}>{row.id}</TableCell>
                                        <TableCell sx={{ fontWeight: 600, color: '#fff' }}>{row.destination}</TableCell>
                                        <TableCell sx={{ color: '#aaa' }}>{row.date}</TableCell>
                                        <TableCell>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                                <Box sx={{ width: '100%', mr: 1 }}>
                                                    <LinearProgress
                                                        variant="determinate"
                                                        value={loadPercentage}
                                                        sx={{
                                                            height: 8,
                                                            borderRadius: 4,
                                                            backgroundColor: 'rgba(255,255,255,0.1)',
                                                            '& .MuiLinearProgress-bar': { backgroundColor: barColor, borderRadius: 4, boxShadow: `0 0 10px ${barColor}` }
                                                        }}
                                                    />
                                                </Box>
                                                <Box sx={{ minWidth: 35 }}>
                                                    <Typography variant="body2" sx={{ color: barColor, fontWeight: 700 }}>{loadPercentage}%</Typography>
                                                </Box>
                                            </Box>
                                            <Typography variant="caption" sx={{ color: '#666', mt: 0.5, display: 'block' }}>
                                                {row.booked} из {row.capacity} мест
                                            </Typography>
                                        </TableCell>
                                    </TableRow>
                                );
                            })
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
}

export default FlightLoad;