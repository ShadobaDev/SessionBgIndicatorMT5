//+------------------------------------------------------------------+
//|                                             class_SessionDay.mqh |
//|                                       Copyright 2026, ShadobaDev |
//|              https://github.com/ShadobaDev/SessionBgIndicatorMT5 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, ShadobaDev"
#property link      "https://github.com/ShadobaDev/SessionBgIndicatorMT5"
#property version   "1.00"
#property strict

/**
 * \brief Defines session rectangle data and per-day session calculations
 *
 * This class is responsible for calculating the time and price rectangles
 * for each trading session (Tokyo, London, New York) for a given day. It also
 * determines visibility based on trading days and configured day ranges.
 *
 * The `SessionCanvasManager` class creates instances of `SessionDay` for each
 * visible day and uses their calculated rectangles to render on the canvas.
 */
class CanvasRectangle
{
public:
    datetime _t1, _t2;  //!< Start and end times of the rectangle (in chart time)
    int _b1, _b2;       //!< Start and end bars of the rectangle (in chart time)
    double _p1, _p2;    //!< Highest and lowest prices in the rectangle range
    uint _color;        //!< Color for rendering the rectangle
};

/**
 * \brief Enum with 96 values (24h × 4 quarters)
 * Used to specify session start and end times in 15-minute increments.
 */ 
enum SessionTime
{
   // 00:00 - 00:45
   H00_M00, // 00:00
   H00_M15, // 00:15
   H00_M30, // 00:30
   H00_M45, // 00:45
   
   // 01:00 - 01:45
   H01_M00, // 01:00
   H01_M15, // 01:15
   H01_M30, // 01:30
   H01_M45, // 01:45
   
   // 02:00 - 02:45
   H02_M00, // 02:00
   H02_M15, // 02:15
   H02_M30, // 02:30
   H02_M45, // 02:45
   
   // 03:00 - 03:45
   H03_M00, // 03:00
   H03_M15, // 03:15
   H03_M30, // 03:30
   H03_M45, // 03:45
   
   // 04:00 - 04:45
   H04_M00, // 04:00
   H04_M15, // 04:15
   H04_M30, // 04:30
   H04_M45, // 04:45
   
   // 05:00 - 05:45
   H05_M00, // 05:00
   H05_M15, // 05:15
   H05_M30, // 05:30
   H05_M45, // 05:45
   
   // 06:00 - 06:45
   H06_M00, // 06:00
   H06_M15, // 06:15
   H06_M30, // 06:30
   H06_M45, // 06:45
   
   // 07:00 - 07:45
   H07_M00, // 07:00
   H07_M15, // 07:15
   H07_M30, // 07:30
   H07_M45, // 07:45
   
   // 08:00 - 08:45
   H08_M00, // 08:00
   H08_M15, // 08:15
   H08_M30, // 08:30
   H08_M45, // 08:45
   
   // 09:00 - 09:45
   H09_M00, // 09:00
   H09_M15, // 09:15
   H09_M30, // 09:30
   H09_M45, // 09:45
   
   // 10:00 - 10:45
   H10_M00, // 10:00
   H10_M15, // 10:15
   H10_M30, // 10:30
   H10_M45, // 10:45
   
   // 11:00 - 11:45
   H11_M00, // 11:00
   H11_M15, // 11:15
   H11_M30, // 11:30
   H11_M45, // 11:45
   
   // 12:00 - 12:45
   H12_M00, // 12:00
   H12_M15, // 12:15
   H12_M30, // 12:30
   H12_M45, // 12:45
   
   // 13:00 - 13:45
   H13_M00, // 13:00
   H13_M15, // 13:15
   H13_M30, // 13:30
   H13_M45, // 13:45
   
   // 14:00 - 14:45
   H14_M00, // 14:00
   H14_M15, // 14:15
   H14_M30, // 14:30
   H14_M45, // 14:45
   
   // 15:00 - 15:45
   H15_M00, // 15:00
   H15_M15, // 15:15
   H15_M30, // 15:30
   H15_M45, // 15:45
   
   // 16:00 - 16:45
   H16_M00, // 16:00
   H16_M15, // 16:15
   H16_M30, // 16:30
   H16_M45, // 16:45
   
   // 17:00 - 17:45
   H17_M00, // 17:00
   H17_M15, // 17:15
   H17_M30, // 17:30
   H17_M45, // 17:45
   
   // 18:00 - 18:45
   H18_M00, // 18:00
   H18_M15, // 18:15
   H18_M30, // 18:30
   H18_M45, // 18:45
   
   // 19:00 - 19:45
   H19_M00, // 19:00
   H19_M15, // 19:15
   H19_M30, // 19:30
   H19_M45, // 19:45
   
   // 20:00 - 20:45
   H20_M00, // 20:00
   H20_M15, // 20:15
   H20_M30, // 20:30
   H20_M45, // 20:45
   
   // 21:00 - 21:45
   H21_M00, // 21:00
   H21_M15, // 21:15
   H21_M30, // 21:30
   H21_M45, // 21:45
   
   // 22:00 - 22:45
   H22_M00, // 22:00
   H22_M15, // 22:15
   H22_M30, // 22:30
   H22_M45, // 22:45
   
   // 23:00 - 23:45
   H23_M00, // 23:00
   H23_M15, // 23:15
   H23_M30, // 23:30
   H23_M45  // 23:45
};

#define TOKYO 0
#define LONDON 1
#define NEWYORK 2 

/**
 * \brief Holds shared session parameters and day range configuration
 *
 * This struct is used to store the session start/end times, colors, and
 * the range of days to display (From/To). It is shared across all `SessionDay`
 * instances to ensure consistent configuration.
 */
class SessionDayParams
{
public:
    SessionTime m_start[3];     //<! Session start  
    SessionTime m_end[3];       //<! Session end
    color       m_color[3];     //<! Session colors for TOKYO, LONDON, NEWYORK
    int m_daysTo;               //<! Number of days to show in the past (e.g. 0 = today, 1 = yesterday, etc.)
    int m_daysFrom;             //<! Number of days to show in the future (e.g. 0 = today, 1 = tomorrow, etc.)
};

/**
 * \brief Enum to specify rendering type for a session day
 * Used to determine whether to render individual session rectangles or a full-day rectangle.
 */
enum RenderType
{
    SESSIONS,       //!< Render individual session rectangles (Tokyo, London, New York)
    DAY             //!< Render a single rectangle for the entire day (used when day is outside session range)
};

/**
 * \brief Holds session rectangle data and computes per-day session geometry
 *
 * Responsible for converting session times into chart-time rectangles and
 * computing price extremes for the rectangle range.
 */
class SessionDay
{
private:
    int         m_totalWidth;       //<! Total width of the day in pixels (used for rendering)
    int         m_totalHeight;      //<! Total height of the chart in pixels (used for rendering)
    bool        m_Visible;          //<! Whether this day should be rendered (based on trading day and day range)
    RenderType  m_type;             //<! Type of rendering (SESSIONS or DAY)
    
    CanvasRectangle        m_rectangles[3];     //<! Rectangles for Tokyo, London, New York sessions
    CanvasRectangle        m_absoluteRectangle; //<! Rectangle for the entire day (used when rendering full day instead of sessions)
    
    SessionDayParams* m_params;     //<! Pointer to shared session parameters (times, colors, day range)
    
public:
    /**
     * \brief Constructor: initializes session day with optional parameters
     * \param params Pointer to shared session parameters (can be set later with InsertParams)
     */
    SessionDay(SessionDayParams * params = NULL) : m_params(params), m_Visible(false), m_type(SESSIONS)
    {}
    
    /** \brief Destructor: no dynamic memory to clean up */
    ~SessionDay() {}
    
    
    /** \brief Attach shared session parameters */
    void InsertParams(SessionDayParams * params)
    {
        m_params = params;
    }
    
    /** \brief Get pointer to session rectangle by index (0..2) */
    CanvasRectangle * GetRectangle(int idx)
    {
        if(idx >= 3) return NULL;
        
        return &m_rectangles[idx];
    }
    
    /** \brief Get pointer to absolute-day rectangle (used when rendering full day) */
    CanvasRectangle * GetAbsoluteRectangle()
    {   
        return &m_absoluteRectangle;
    }
    
    bool GetVisibilty() const { return m_Visible; }
    void SetVisibilty(bool visible) { m_Visible=visible; }
    RenderType GetType() const { return m_type; }
    
    /**
     * \brief Calculate session rectangles for the given day index
     * \param day 0 = today, 1 = yesterday, etc.
     */
    void Calculate(int day)
    {   
        if (_Period == PERIOD_W1 || _Period == PERIOD_MN1) return;

        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        dt.hour = 0; dt.min = 0; dt.sec = 0;
        datetime startOfToday = StructToTime(dt);
        
        datetime startTime, endTime;
        int count;
        
        if(day == 0) {
            // Today's day: from midnight to now
            startTime = startOfToday;
            endTime   = TimeCurrent(); 
        } else {
            // Past days: shift backward by multiples of 24h
            startTime = startOfToday - (day * 86400);
            endTime   = startTime + 86400 - 1; // End of day: 23:59:59
        }
        
        if(IsTradingDay(startTime+1))
        {
            m_Visible = true;
        }
        else
        {
            m_Visible = false;
            return;
        }
        
        if(IsDayInRange(startTime+1))
        {
            m_type = SESSIONS;
        }
        else
        {
            m_type = DAY;
            m_absoluteRectangle._t1 = startTime;
            m_absoluteRectangle._t2 = endTime+1;
            m_absoluteRectangle._color = m_params.m_color[NEWYORK];
            m_absoluteRectangle._b1 = iBarShift(_Symbol, _Period, startTime);
            m_absoluteRectangle._b2 = iBarShift(_Symbol, _Period, endTime)-1;
            count = m_absoluteRectangle._b1 - m_absoluteRectangle._b2 + 1;
            m_absoluteRectangle._p1 = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, count, m_absoluteRectangle._b2));
            m_absoluteRectangle._p2 = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, count,  m_absoluteRectangle._b2));
            
            return;
        } 
        
        // New York Session
        int nyStartMinutes = SessionTimeToMinutes(m_params.m_start[NEWYORK]);
        int nyEndMinutes = SessionTimeToMinutes(m_params.m_end[NEWYORK]);
        datetime nyStart = startTime + nyStartMinutes * 60;
        datetime nyEnd = startTime + nyEndMinutes * 60;
        if(nyEndMinutes < nyStartMinutes) nyEnd += 86400; // Past the midnight?
        
        m_rectangles[NEWYORK]._t1 = nyStart;
        m_rectangles[NEWYORK]._t2 = nyEnd;
        m_rectangles[NEWYORK]._color = m_params.m_color[NEWYORK];
        m_rectangles[NEWYORK]._b1 = iBarShift(_Symbol, _Period, nyStart);
        m_rectangles[NEWYORK]._b2 = iBarShift(_Symbol, _Period, nyEnd);
        count = m_rectangles[NEWYORK]._b1 - m_rectangles[NEWYORK]._b2 + 1;
        m_rectangles[NEWYORK]._p1 = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, count, m_rectangles[NEWYORK]._b2));
        m_rectangles[NEWYORK]._p2 = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, count,  m_rectangles[NEWYORK]._b2));
        
        // London Session
        int ldStartMinutes = SessionTimeToMinutes(m_params.m_start[LONDON]);
        int ldEndMinutes = SessionTimeToMinutes(m_params.m_end[LONDON]);
        datetime ldStart = startTime + ldStartMinutes * 60;
        datetime ldEnd = startTime + ldEndMinutes * 60;
        if(ldEndMinutes < ldStartMinutes) ldEnd += 86400;
        
        m_rectangles[LONDON]._t1 = ldStart;
        m_rectangles[LONDON]._t2 = ldEnd;
        m_rectangles[LONDON]._color = m_params.m_color[LONDON];
        m_rectangles[LONDON]._b1 = iBarShift(_Symbol, _Period, ldStart);
        m_rectangles[LONDON]._b2 = iBarShift(_Symbol, _Period, ldEnd);
        count = m_rectangles[LONDON]._b1 - m_rectangles[LONDON]._b2 + 1;
        m_rectangles[LONDON]._p1 = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, count, m_rectangles[LONDON]._b2));
        m_rectangles[LONDON]._p2 = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, count,  m_rectangles[LONDON]._b2));
        
        // TOKYO Session
        int tkStartMinutes = SessionTimeToMinutes(m_params.m_start[TOKYO]);
        int tkEndMinutes = SessionTimeToMinutes(m_params.m_end[TOKYO]);
        datetime tkStart = startTime + tkStartMinutes * 60;
        datetime tkEnd = startTime + tkEndMinutes * 60;
        if(tkEndMinutes < tkStartMinutes) tkEnd += 86400;
        
        m_rectangles[TOKYO]._t1 = tkStart;
        m_rectangles[TOKYO]._t2 = tkEnd;
        m_rectangles[TOKYO]._color = m_params.m_color[TOKYO];
        m_rectangles[TOKYO]._b1 = iBarShift(_Symbol, _Period, tkStart);
        m_rectangles[TOKYO]._b2 = iBarShift(_Symbol, _Period, tkEnd);
        count = m_rectangles[TOKYO]._b1 - m_rectangles[TOKYO]._b2 + 1;
        m_rectangles[TOKYO]._p1 = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, count, m_rectangles[TOKYO]._b2));
        m_rectangles[TOKYO]._p2 = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, count,  m_rectangles[TOKYO]._b2));
    }
    
protected:
    /** 
     * \brief Convert SessionTime enum to HH:MM string 
     * \param st Session time to convert
     */
    string SessionTimeToString(SessionTime st)
    {
       int minutes = SessionTimeToMinutes(st);
       int hour = minutes / 60;
       int minute = minutes % 60;
       return StringFormat("%02d:%02d", hour, minute);
    }
    
    /** 
     * \brief Convert SessionTime enum to minutes since midnight 
     * \param st Session time to convert
     */
    int SessionTimeToMinutes(SessionTime st)
    {
       // Each element of the enum corresponds to a 15-minute interval.
       // The values of the enum are indexed from 0 (H00_M00) to 95 (H23_M45).
       // Minutes = (hour * 60) + minute
       // hour = floor(index / 4)
       // minute = (index % 4) * 15
       int index = (int)st;
       int hour = index / 4;
       int minute = (index % 4) * 15;
       return hour * 60 + minute;
    }
    
    
    /** 
     * \brief Return true if the date is a trading day (Mon-Fri) 
     * \param dateToCheck Date to check for trading day status
     */
    bool IsTradingDay(datetime dateToCheck) {
        MqlDateTime dt;
        TimeToStruct(dateToCheck, dt);
    
        if (dt.day_of_week == 0 || dt.day_of_week == 6) {
            return false; 
        }
        
        return true;
    }
    
    /** 
     * \brief Check if the day is within configured From/To range
     * The range is defined in terms of number of days from today (negative for past, positive for future).
     */
    bool IsDayInRange(datetime checkTime) 
    {
        if (m_params.m_daysTo >= m_params.m_daysFrom)
        {
            int tmp = m_params.m_daysTo;
            m_params.m_daysTo = m_params.m_daysFrom;
            m_params.m_daysFrom = tmp;
        }
        
        datetime serverNow = TimeCurrent();
        datetime currentDate = serverNow - (serverNow % 86400);
        datetime checkDate = checkTime - (checkTime % 86400);
        
        long secondsDiff = MathAbs(checkDate - currentDate);
        int daysDiff = (int)(secondsDiff / 86400); // Note: MathAbs not used here
        
        //PrintFormat("daysDiff=%d, m_params.m_daysFrom=%d, m_params.m_daysTo=%d",daysDiff, m_params.m_daysFrom, m_params.m_daysTo);
        
        return (daysDiff <= m_params.m_daysFrom && daysDiff >= m_params.m_daysTo);
    }
};

