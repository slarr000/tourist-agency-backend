import { useState, useEffect } from 'react'

function TouristCount() {
    const [report, setReport] = useState(null);
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [category, setCategory] = useState('');

    const fetchData = () => {
        // Собираем параметры в строку запроса
        const params = new URLSearchParams();
        if (startDate) params.append('startDate', startDate);
        if (endDate) params.append('endDate', endDate);
        if (category) params.append('category', category);

        fetch(`http://localhost:5000/api/Reports/tourists-count?${params.toString()}`)
            .then(response => response.json())
            .then(result => setReport(result))
            .catch(error => console.error('Ошибка:', error));
    };

    useEffect(() => {
        fetchData();
    }, []);

    return (
        <div>
            <h2>3. Количество туристов за период</h2>

            <div style={{ marginBottom: '20px', display: 'flex', gap: '10px' }}>
                <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} />
                <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} />
                <select value={category} onChange={e => setCategory(e.target.value)}>
                    <option value="">Все категории</option>
                    <option value="Отдых">Отдых</option>
                    <option value="Шоп-тур">Шоп-тур</option>
                </select>
                <button onClick={fetchData}>Рассчитать</button>
            </div>

            {report && (
                <div style={{ padding: '20px', backgroundColor: '#2d2d2d', borderRadius: '5px' }}>
                    <h3>Результат:</h3>
                    <p><strong>Всего туристов:</strong> {report.totalTourists}</p>
                    <p><strong>Категория:</strong> {report.category}</p>
                </div>
            )}
        </div>
    )
}

export default TouristCount;