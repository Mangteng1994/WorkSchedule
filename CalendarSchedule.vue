<template> 
 
    <div class="calendar-container"> 
    
    <h1 class="calendar-title">{{ currentYear }}年{{ currentMonth }}月排班表</h1> 
    
    <div class="calendar-controls"> 
    
    <div class="year-month-selector"> 
    
    <label for="year">年份：</label> 
    
    <select id="year" v-model="currentYear" @change="generateCalendar"> 
    
    <option v-for="year in yearOptions" :key="year" :value="year">{{ year }}</option> 
    
    </select> 
    
    <label for="month">月份：</label> 
    
    <select id="month" v-model="currentMonth" @change="generateCalendar"> 
    
    <option v-for="month in 12" :key="month" :value="month">{{ month }}</option> 
    
    </select> 
    
    <!-- <button @click="generateCalendar" class="generate-btn">生成排班表</button> -->
    
    </div> 
    
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
    
    :class="getShiftClass(day.shift)" 
    
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
    
    return { 
    
    currentYear: new Date().getFullYear(),  // 获取当前年份 
    
    currentMonth: new Date().getMonth() + 1,  // 获取当前月份（注意JavaScript中月份从0开始） 
    
    weekDays: ['周日', '周一', '周二', '周三', '周四', '周五', '周六'], 
    
    yearOptions: Array.from({ length: 101 }, (_, i) => 2000 + i), 
    
    calendarData: [], 
    
    // 排班规则配置 
    
    baseDate: new Date(2025, 3, 26), // 2025-04-26 基准日期 
    
    shiftOrder: ['夜班', '下班', '休息', '休息', '白班', '连班'] 
    
    } 
    
    }, 
    
    mounted() { 
    
    this.generateCalendar();  // 组件挂载时自动生成日历 
    
    }, 
    
    methods: { 
    
    generateCalendar() { 
    
    const year = this.currentYear; 
    
    const month = this.currentMonth; 
    
    // 获取当月第一天和最后一天 
    
    const firstDay = new Date(year, month - 1, 1); 
    
    const lastDay = new Date(year, month, 0); 
    
    const daysInMonth = lastDay.getDate(); 
    
    // 获取第一天是星期几 (0-6, 0表示周日) 
    
    const firstDayOfWeek = firstDay.getDay(); 
    
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
    
    const dayOfWeek = currentDate.getDay(); 
    
    // 如果是新的一周，添加新行 
    
    if (dayOfWeek === 0 && day > 1) { 
    
    this.calendarData.push([...currentWeek]); 
    
    currentWeek = Array(7).fill().map(() => ({ date: null, shift: null })); 
    
    } 
    
    // 计算排班 
    
    const shift = this.getShift(currentDate); 
    
    // 填充当前日期 
    
    currentWeek[dayOfWeek] = { 
    
    date: day, 
    
    shift: shift 
    
    }; 
    
    } 
    
    // 添加最后一周 
    
    this.calendarData.push([...currentWeek]); 
    
    }, 
    
    getShift(date) {
        // 计算与基准日期的天数差，不使用绝对值
        const diffTime = date - this.baseDate;
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        // 使用模运算获取排班，确保结果为正数
        const index = ((diffDays % 6) + 6) % 6;
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
    
    margin-bottom: 20px; 
    
    } 
    
    .year-month-selector { 
    
    display: flex; 
    
    align-items: center; 
    
    gap: 10px; 
    
    } 
    
    .year-month-selector select { 
    
    padding: 5px 10px; 
    
    border-radius: 4px; 
    
    border: 1px solid #ccc; 
    
    } 
    
    .generate-btn { 
    
    padding: 5px 15px; 
    
    background-color: #4CAF50; 
    
    color: white; 
    
    border: none; 
    
    border-radius: 4px; 
    
    cursor: pointer; 
    
    } 
    
    .generate-btn:hover { 
    
    background-color: #45a049; 
    
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
    
    </style>