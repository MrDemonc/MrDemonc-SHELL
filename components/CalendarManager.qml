pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: mgr

    property bool calendarOpen: false
    property var viewedDate: new Date()
    property var selectedDate: new Date()
    property var todayDate: new Date()
    property var daysModel: []

    // Nombres en español
    readonly property var monthNames: [
        "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ]
    readonly property var dayNamesShort: ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
    readonly property var dayNamesFull: ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]

    // Textos formateados en tiempo real
    readonly property string viewedMonthName: monthNames[viewedDate.getMonth()]
    readonly property int viewedYear: viewedDate.getFullYear()
    readonly property string viewedMonthYearStr: `${viewedMonthName} ${viewedYear}`

    readonly property string todayDayName: dayNamesFull[todayDate.getDay()]
    readonly property string todayMonthName: monthNames[todayDate.getMonth()]
    readonly property string todayFormattedDate: `${todayDayName}, ${todayDate.getDate()} de ${todayMonthName} de ${todayDate.getFullYear()}`

    readonly property string selectedDayName: dayNamesFull[selectedDate.getDay()]
    readonly property string selectedMonthName: monthNames[selectedDate.getMonth()]
    readonly property string selectedFormattedDate: `${selectedDayName}, ${selectedDate.getDate()} de ${selectedMonthName} de ${selectedDate.getFullYear()}`

    // Reloj digital en vivo
    property string liveTimeStr: "00:00:00"
    property int weekNumber: 1
    property int dayOfYear: 1

    // Monitoreo del toggle SUPER + ALT
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_calendar.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    mgr.toggle();
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            mgr.todayDate = now;
            let h = String(now.getHours()).padStart(2, '0');
            let m = String(now.getMinutes()).padStart(2, '0');
            let s = String(now.getSeconds()).padStart(2, '0');
            mgr.liveTimeStr = `${h}:${m}:${s}`;

            mgr.dayOfYear = mgr.calculateDayOfYear(now);
            mgr.weekNumber = mgr.calculateWeekNumber(now);
        }
    }

    function calculateDayOfYear(d) {
        let start = new Date(d.getFullYear(), 0, 0);
        let diff = d - start;
        let oneDay = 1000 * 60 * 60 * 24;
        return Math.floor(diff / oneDay);
    }

    function calculateWeekNumber(d) {
        let target = new Date(d.valueOf());
        let dayNr = (d.getDay() + 6) % 7;
        target.setDate(target.getDate() - dayNr + 3);
        let firstThursday = target.valueOf();
        target.setMonth(0, 1);
        if (target.getDay() !== 4) {
            target.setMonth(0, 1 + ((4 - target.getDay()) + 7) % 7);
        }
        return 1 + Math.ceil((firstThursday - target) / (7 * 24 * 3600 * 1000));
    }

    function updateDaysModel() {
        let year = viewedDate.getFullYear();
        let month = viewedDate.getMonth();

        let firstDayOfMonth = new Date(year, month, 1);
        // Lunes = 0, ..., Domingo = 6
        let firstDayOfWeekOffset = (firstDayOfMonth.getDay() + 6) % 7;

        let totalDaysCurrent = new Date(year, month + 1, 0).getDate();
        let totalDaysPrev = new Date(year, month, 0).getDate();

        let today = new Date();
        let isTodayYear = today.getFullYear();
        let isTodayMonth = today.getMonth();
        let isTodayDate = today.getDate();

        let selYear = selectedDate.getFullYear();
        let selMonth = selectedDate.getMonth();
        let selDate = selectedDate.getDate();

        let list = [];

        // 1. Días del mes anterior (si los hay)
        for (let i = firstDayOfWeekOffset - 1; i >= 0; i--) {
            let dayNum = totalDaysPrev - i;
            let d = new Date(year, month - 1, dayNum);
            let dWeek = (d.getDay() + 6) % 7;
            list.push({
                dayNumber: dayNum,
                date: d,
                isCurrentMonth: false,
                isToday: (d.getFullYear() === isTodayYear && d.getMonth() === isTodayMonth && d.getDate() === isTodayDate),
                isSelected: (d.getFullYear() === selYear && d.getMonth() === selMonth && d.getDate() === selDate),
                isWeekend: (dWeek === 5 || dWeek === 6)
            });
        }

        // 2. Días del mes actual
        for (let day = 1; day <= totalDaysCurrent; day++) {
            let d = new Date(year, month, day);
            let dWeek = (d.getDay() + 6) % 7;
            list.push({
                dayNumber: day,
                date: d,
                isCurrentMonth: true,
                isToday: (year === isTodayYear && month === isTodayMonth && day === isTodayDate),
                isSelected: (year === selYear && month === selMonth && day === selDate),
                isWeekend: (dWeek === 5 || dWeek === 6)
            });
        }

        // 3. Días del mes siguiente para completar la cuadrícula de 42 celdas (6 semanas)
        let remaining = 42 - list.length;
        for (let day = 1; day <= remaining; day++) {
            let d = new Date(year, month + 1, day);
            let dWeek = (d.getDay() + 6) % 7;
            list.push({
                dayNumber: day,
                date: d,
                isCurrentMonth: false,
                isToday: (d.getFullYear() === isTodayYear && d.getMonth() === isTodayMonth && d.getDate() === isTodayDate),
                isSelected: (d.getFullYear() === selYear && d.getMonth() === selMonth && d.getDate() === selDate),
                isWeekend: (dWeek === 5 || dWeek === 6)
            });
        }

        daysModel = list;
    }

    function open() {
        let n = new Date();
        todayDate = n;
        viewedDate = new Date(n.getFullYear(), n.getMonth(), n.getDate());
        selectedDate = new Date(n.getFullYear(), n.getMonth(), n.getDate());
        updateDaysModel();
        calendarOpen = true;
    }

    function close() {
        calendarOpen = false;
    }

    function toggle() {
        if (calendarOpen) {
            close();
        } else {
            open();
        }
    }

    function prevMonth() {
        let y = viewedDate.getFullYear();
        let m = viewedDate.getMonth();
        viewedDate = new Date(y, m - 1, 1);
        updateDaysModel();
    }

    function nextMonth() {
        let y = viewedDate.getFullYear();
        let m = viewedDate.getMonth();
        viewedDate = new Date(y, m + 1, 1);
        updateDaysModel();
    }

    function prevYear() {
        let y = viewedDate.getFullYear();
        let m = viewedDate.getMonth();
        viewedDate = new Date(y - 1, m, 1);
        updateDaysModel();
    }

    function nextYear() {
        let y = viewedDate.getFullYear();
        let m = viewedDate.getMonth();
        viewedDate = new Date(y + 1, m, 1);
        updateDaysModel();
    }

    function goToToday() {
        let n = new Date();
        viewedDate = new Date(n.getFullYear(), n.getMonth(), n.getDate());
        selectedDate = new Date(n.getFullYear(), n.getMonth(), n.getDate());
        updateDaysModel();
    }

    function selectDay(d) {
        selectedDate = new Date(d);
        if (d.getFullYear() !== viewedDate.getFullYear() || d.getMonth() !== viewedDate.getMonth()) {
            viewedDate = new Date(d.getFullYear(), d.getMonth(), 1);
        }
        updateDaysModel();
    }

    function getDaysDiffText(d) {
        let today = new Date(todayDate.getFullYear(), todayDate.getMonth(), todayDate.getDate());
        let target = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        let diffMs = target - today;
        let diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));
        if (diffDays === 0) return "Hoy";
        if (diffDays === 1) return "Mañana";
        if (diffDays === -1) return "Ayer";
        if (diffDays > 1) return `En ${diffDays} días`;
        return `Hace ${Math.abs(diffDays)} días`;
    }
}
