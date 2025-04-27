<template>
    <div class="calendar-container">
        <h1 class="calendar-title">{{ currentYear }}年{{ currentMonth }}月排班表</h1>

        <div class="calendar-controls">
            <!-- 移除包裹 div -->
            <label for="year">年份：</label>
            <select id="year" v-model="currentYear" @change="generateCalendar">
                <option v-for="year in yearOptions" :key="year" :value="year">{{ year }}</option>
            </select>
            <label for="month">月份：</label>
            <select id="month" v-model="currentMonth" @change="generateCalendar">
                <option v-for="month in 12" :key="month" :value="month">{{ month }}</option>
            </select>
            <!-- 配置按钮保持不变 -->
            <button @click="toggleConfig" class="config-btn" title="配置">⚙️</button>
        </div>

        <!-- 新增配置区域 -->
        <div v-if="showConfig" class="config-section">
            <h3>排班规则配置</h3>
            <div class="config-item">
                <label for="baseDate">基准日期：</label>
                <input type="date" id="baseDate" v-model="newBaseDateInput">
            </div>
            <div class="config-item">
                <label for="shiftOrder">班次顺序 (英文逗号分隔)：</label>
                <input type="text" id="shiftOrder" v-model="newShiftOrderInput" placeholder="例如: 夜班,下班,休息,休息,白班,连班">
            </div>
            <button @click="saveConfig" class="save-btn">保存</button>
        </div>

        <div class="calendar-grid">
            <div class="calendar-header">
                <div class="calendar-cell" v-for="day in weekDays" :key="day">{{ day }}</div>
            </div>

            <div class="calendar-body">
                <div v-for="(week, weekIndex) in calendarData" :key="weekIndex" class="calendar-row">
                    <div
                        v-for="(day, dayIndex) in week"
                        :key="`${weekIndex}-${dayIndex}`"
                        class="calendar-cell"
                        :class="[getShiftClass(day.shift), {'today': day.isToday}]"
                    >
                        <template v-if="day.date">
                            <div class="day-number">{{ day.date }}</div>
                            <div class="shift-name" :class="{ 'rest-day': day.shift === '休息' }">{{ day.shift }}</div>
                        </template>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'CalendarSchedule',
    data() {
        // 尝试从 localStorage 加载配置
        const savedBaseDate = localStorage.getItem('scheduleBaseDate');
        const savedShiftOrder = localStorage.getItem('scheduleShiftOrder');

        const initialBaseDate = savedBaseDate ? this.parseDateFromInput(savedBaseDate) : new Date(2025, 3, 26); // 默认 2025-04-26
        const initialShiftOrder = savedShiftOrder ? savedShiftOrder.split(',') : ['夜班', '下班', '休息', '休息', '白班', '连班']; // 默认班次

        return {
            currentYear: new Date().getFullYear(),
            currentMonth: new Date().getMonth() + 1,
            weekDays: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
            yearOptions: Array.from({ length: 101 }, (_, i) => 2000 + i),
            calendarData: [],
            // 排班规则配置 (从 localStorage 或默认值初始化)
            baseDate: initialBaseDate,
            shiftOrder: initialShiftOrder,
            // 配置界面相关
            showConfig: false,
            newBaseDateInput: this.formatDateForInput(initialBaseDate), // 用于 input[type=date] 的 YYYY-MM-DD 格式
            newShiftOrderInput: initialShiftOrder.join(','), // 用于 input[type=text] 的逗号分隔字符串
        }
    },
    mounted() {
        // 不再需要 loadConfig，因为已在 data 中初始化
        this.generateCalendar(); // 组件挂载时生成日历
    },
    methods: {
        formatDateForInput(date) {
            if (!date) return '';
            const year = date.getFullYear();
            const month = (date.getMonth() + 1).toString().padStart(2, '0');
            const day = date.getDate().toString().padStart(2, '0');
            return `${year}-${month}-${day}`;
        },
        parseDateFromInput(dateString) {
            if (!dateString) return null;
            // 注意：直接 new Date(YYYY-MM-DD) 在某些浏览器/时区下可能有问题
            // 更可靠的方式是分别提取年、月、日
            const parts = dateString.split('-');
            if (parts.length === 3) {
                const year = parseInt(parts[0], 10);
                const month = parseInt(parts[1], 10) - 1; // 月份从0开始
                const day = parseInt(parts[2], 10);
                return new Date(year, month, day);
            }
            return null; // 或返回默认日期/抛出错误
        },
        toggleConfig() {
            this.showConfig = !this.showConfig;
            // 如果显示配置，用当前生效的配置填充输入框
            if (this.showConfig) {
                this.newBaseDateInput = this.formatDateForInput(this.baseDate);
                this.newShiftOrderInput = this.shiftOrder.join(',');
            }
        },
        saveConfig() {
            // 验证日期
            const newDate = this.parseDateFromInput(this.newBaseDateInput);
            if (!newDate) {
                alert('输入的基准日期格式无效！请使用 YYYY-MM-DD 格式。');
                return;
            }

            // 验证班次顺序
            const newOrder = this.newShiftOrderInput.split(',').map(s => s.trim()).filter(s => s); // 分割、去首尾空格、过滤空字符串
            if (newOrder.length === 0) {
                alert('班次顺序不能为空！');
                return;
            }

            // 更新数据
            this.baseDate = newDate;
            this.shiftOrder = newOrder;

            // 保存到 localStorage
            localStorage.setItem('scheduleBaseDate', this.newBaseDateInput);
            localStorage.setItem('scheduleShiftOrder', this.newShiftOrderInput);

            // 重新生成日历并关闭配置区域
            this.generateCalendar();
            this.showConfig = false;
            alert('配置已保存！');
        },
        generateCalendar() {
            const year = this.currentYear;
            const month = this.currentMonth;
            const today = new Date();
            const isCurrentMonth = today.getFullYear() === year && today.getMonth() + 1 === month;
            // 获取当月第一天和最后一天
            const firstDay = new Date(year, month - 1, 1);
            const lastDay = new Date(year, month, 0);
            const daysInMonth = lastDay.getDate();
            // 获取第一天是星期几 (0-6, 0表示周日)
            const firstDayOfWeek = (firstDay.getDay() + 6) % 7; // 调整为周一开始
            // 初始化日历数据
            this.calendarData = [];
            let currentWeek = Array(7).fill().map(() => ({ date: null, shift: null }));

            // 填充前导空白
            for (let i = 0; i < firstDayOfWeek; i++) {
                currentWeek[i] = { date: null, shift: null };
            }
            // 填充日期和排班
            for (let day = 1; day <= daysInMonth; day++) {
                const currentDate = new Date(year, month - 1, day);
                const dayOfWeek = (currentDate.getDay() + 6) % 7; // 调整为周一开始
                // 如果是新的一周，添加新行
                if (dayOfWeek === 0 && day > 1) {
                    this.calendarData.push([...currentWeek]);
                    currentWeek = Array(7).fill().map(() => ({ date: null, shift: null }));
                }
                // 计算排班
                const shift = this.getShift(currentDate); // getShift 会使用更新后的 this.baseDate 和 this.shiftOrder

                // 填充当前日期
                currentWeek[dayOfWeek] = {
                    date: day,
                    shift: shift,
                    isToday: isCurrentMonth && day === today.getDate()
                };
            }
            // 添加最后一周
            this.calendarData.push([...currentWeek]);
        },
        getShift(date) {
            // 计算与基准日期的天数差，不使用绝对值
            const diffTime = date - this.baseDate;
            // 确保除以 24 小时的毫秒数
            const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

            // 使用模运算获取排班，确保结果为正数，并使用当前 shiftOrder 的长度
            const len = this.shiftOrder.length;
            if (len === 0) return '错误:无班次'; // 处理班次为空的情况
            const index = ((diffDays % len) + len) % len;
            return this.shiftOrder[index];
        },
        getShiftClass(shift) {
            if (!shift) return '';
            switch (shift) {
                case '夜班': return 'night-shift';
                case '白班': return 'day-shift';
                case '连班': return 'continuous-shift';
                case '休息': return 'rest-day';
                default: return '';
            }
        }
    }
}
</script>

<style scoped>
.calendar-container {
    max-width: 1000px;
    margin: 0 auto;
    padding: 20px;
    font-family: Arial, sans-serif;
}
.calendar-title {
    text-align: center;
    margin-bottom: 20px;
    font-size: 24px;
}
.calendar-controls {
    display: flex;
    justify-content: center;
    align-items: center; /* 垂直居中对齐 */
    margin-bottom: 20px;
    gap: 10px; /* 控制年份、月份、按钮之间的主要间距 */
    flex-wrap: wrap; /* 允许在空间极端不足时换行 */
}

/* 移除 .year-month-selector 相关的所有样式规则 */

.calendar-controls label {
    margin-right: 5px; /* 标签和下拉框之间的间距 */
    /* 可以根据需要添加 margin-left 来控制与前一个元素的间距，
       例如给月份标签加 margin-left: 15px; */
}
/* 给月份标签增加左边距，使其与年份选择器分开一些 */
.calendar-controls label[for="month"] {
    margin-left: 15px; /* 增加年月之间的间距 */
}


.calendar-controls select {
    padding: 5px 10px;
    border-radius: 4px;
    border: 1px solid #ccc;
}


.config-btn { /* 配置按钮样式保持不变 */
    padding: 0;
    background-color: transparent;
    color: #333;
    border: none;
    cursor: pointer;
    font-size: 22px;
    line-height: 1;
    height: auto;
    margin-left: 15px; /* 给按钮增加左边距 */
}

.config-btn:hover {
    background-color: transparent;
    color: #007bff;
}

.save-btn { /* 保持保存按钮样式 */
    padding: 5px 15px;
    background-color: #007bff;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    height: 30px;
    line-height: 20px;
}
.save-btn:hover {
    background-color: #0056b3;
}


.config-section {
    border: 1px solid #ccc;
    padding: 15px;
    margin-bottom: 20px;
    border-radius: 4px;
    background-color: #f9f9f9;
}
.config-section h3 {
    margin-top: 0;
    margin-bottom: 15px;
    text-align: center;
}
.config-item {
    margin-bottom: 10px;
    display: flex;
    align-items: center; /* 默认垂直居中 */
    gap: 10px;
    flex-wrap: wrap; /* 允许换行 */
}
.config-item label {
    /* min-width: 100px; */ /* 移除固定最小宽度，使其更灵活 */
    flex-shrink: 0; /* 防止标签被压缩 */
    text-align: right;
    margin-bottom: 5px; /* 在堆叠时增加间距 */
}
.config-item input[type="date"],
.config-item input[type="text"] {
    padding: 5px 10px;
    border-radius: 4px;
    border: 1px solid #ccc;
    flex-grow: 1; /* 输入框占据剩余空间 */
    min-width: 150px; /* 给输入框一个最小宽度 */
}
.save-btn {
    display: block; /* 让保存按钮单独一行 */
    margin: 15px auto 0; /* 顶部留空，水平居中 */
}
.calendar-grid {
    border: 1px solid #ddd;
    border-radius: 4px;
    overflow: hidden;
}
.calendar-header {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    background-color: #f5f5f5;
    font-weight: bold;
}
.calendar-body {
    display: flex;
    flex-direction: column;
}
.calendar-row {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
}
.calendar-cell {
    height: 80px;
    border: 1px solid #ddd;
    padding: 5px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
}
.calendar-header .calendar-cell {
    height: auto;
    padding: 10px;
}
.day-number {
    font-weight: bold;
    margin-bottom: 5px;
}
.shift-name {
    font-size: 14px;
}
/* 班次颜色 */
.night-shift {
    background-color: rgb(255, 230, 204); /* 橙色 */
}
.day-shift {
    background-color: rgb(198, 224, 180); /* 绿色 */
}
.continuous-shift {
    background-color: rgb(220, 230, 250); /* 蓝色 */
}
.rest-day .shift-name {
    color: rgb(150, 150, 150); /* 灰色 */
}
/* 移动端响应式调整 */
@media (max-width: 400px) {
    .config-item {
        /* flex-direction: column; 垂直堆叠 */
        align-items: stretch; /*拉伸项目以填充容器宽度 */
        gap: 1px; /* 减小堆叠时的间距 */
    }
    .config-item label {
        text-align: left; /* 标签左对齐 */
        margin-bottom: 3px; /* 调整标签和输入框间距 */
        /* min-width: auto; */ /* 确保宽度自适应 */
    }
    .config-item input[type="date"],
    .config-item input[type="text"] {
        width: 100%; /* 输入框宽度占满 */
        box-sizing: border-box; /* 防止 padding 导致溢出 */
        min-width: 0; /* 覆盖之前的最小宽度 */
    }
    .calendar-controls {
        /* flex-direction: column; */ /* 注释掉或移除这一行，使其保持水平排列 */
        gap: 8px; /* 在窄屏单行时可以适当减小元素间距 */
        justify-content: space-around; /* 或者使用 space-between 让元素分散对齐 */
    }

    /* 调整窄屏下单行时的间距 */
    .calendar-controls label[for="month"] {
        margin-left: 8px; /* 减小年月之间的间距 */
    }
     .config-btn {
        margin-left: 8px; /* 减小按钮的左边距 */
    }
    .config-item input[type="date"],
    .config-item input[type="text"] {
        width: 100%; /* 输入框宽度占满 */
        box-sizing: border-box; /* 防止 padding 导致溢出 */
        min-width: 0; /* 覆盖之前的最小宽度 */
    }
}
/* 今天日期样式 */
.today {
    border: 1px solid #ff0000 !important;
    box-shadow: 0 0 5px rgba(255, 0, 0, 0.5);
}
</style>