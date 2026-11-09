import { useState, useEffect } from 'react'

function FlightTouristDetails() {
    const [data, setData] = useState([]);
    const [flightNumber, setFlightNumber] = useState('SU-100'); // По умолчанию ищем какой-то рейс

    const fetchData = () => {
        if (!flightNumber) return;

        fetch(`http://localhost:5000/api/Reports/flight-tourist-details?flightNumber=${encodeURIComponent(flightNumber)}`)
            .then(response => response.json())
            .then(result => setData(result))
            .catch(error => console.error('Ошибка:', error));
    };

    useEffect(() => {
        fetchData();
    }, []);

    return (
        <div>
            <h2>15. Подробные сведения о туристах рейса</h2>

            <div style={{ marginBottom: '20px' }}>
                <input
                    type="text"
                    placeholder="Введите номер рейса (напр. SU-100)"
                    value={flightNumber}
                    onChange={(e) => setFlightNumber(e.target.value)}
                    style={{ padding: '5px', marginRight: '10px', width: '250px' }}
                />
                <button onClick={fetchData} style={{ padding: '5px 15px' }}>Найти рейс</button>
            </div>

            {data.length === 0 ? (
                <p>Для рейса {flightNumber} данных не найдено.</p>
            ) : (
                <table border="1" cellPadding="10" style={{ width: '100%' }}>
                    <thead>
                        <tr>
                            <th>ФИО туриста</th>
                            <th>Гостиница</th>
                            <th>Тип груза</th>
                            <th>Вес груза (кг)</th>
                            <th>Номер бирки</th>
                            <th>Маркировка</th>
                        </tr>
                    </thead>
                    <tbody>
                        {data.map((item, index) => (
                            <tr key={index}>
                                <td>{item.fullName}</td>
                                <td>{item.hotelName || '-'}</td>
                                <td>{item.cargoType || 'Без груза'}</td>
                                <td>{item.cargoWeight || '-'}</td>
                                <td>{item.tagNumber || '-'}</td>
                                <td>{item.marking || '-'}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}
        </div>
    )
}

export default FlightTouristDetails;