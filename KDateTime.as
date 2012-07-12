package K_Core
{

 //=================================================================================================
 // this class ported from .NET 1.1 DateTime class.
 // Much easier to use and more robust than the flash datetime classes and compatible with DateTime objects
 // in .NET via the .Ticks property.
 //
 //=================================================================================================
 
 public class KDateTime
 {
 	
	//
	// min/max datetime ranges
	//
	protected static var maxDate:KDateTime;
	public static function get kMAX_DATE() : KDateTime
	{
		if ( maxDate == null )
			maxDate = KDateTime.FromYMD( 2500,12,30 );
			
		return maxDate;
	}
	
	protected static var minDate:KDateTime;
	public static function get kMIN_DATE() : KDateTime
	{
		if ( minDate == null )
			minDate = KDateTime.FromYMD(1, 1, 1);
			
		return minDate;
	}
	
	//
	// for applications that need it you set this to a known tcks offset from server UTC time.
	// See references to "GetUTC.ashx" for how to use this.
	//
	protected static var serverOffset:Number = 0;
	public static function get ServerOffset() : Number { return serverOffset; }
	public static function set ServerOffset( o:Number ) : void { serverOffset = o; }
	
		//
	    // the current date time
	    //
	    public static function get Now() : KDateTime
	    { 	
	    	return new KDateTime( KDateTime.FromFlashDate( new Date() ).Ticks + ServerOffset );
	    }
 	
	  //
	  // 100 nanosecond intervals since 1/1/1. This is the fundamental data for each instance
	  // 
	  
	  protected var ticks:Number;
	  public function get Ticks() : Number
	  {
	   return this.ticks;
	  }
	  
	  //
	  // Assume that this is a UTC time and returns the local time equivalent
	  //
	  public function get LocalTime() : KDateTime
	  {
	  		if ( KDateTime.timeZoneOffset == null )
	  			KDateTime.timeZoneOffset = new Date();
	  			
	  		var local:KDateTime = new KDateTime( this.ticks );
	  			  	
	  		var offset:Number = KDateTime.timeZoneOffset.getTimezoneOffset();
	  		
	  		return local.AddMinutes( -offset );

	  }
	  
	  protected static var timeZoneOffset:Date;
  
  //
  // start day for each month for a 366 day year, valid indices are 0..12
  //
  private static var DaysToMonth366:Array = [ 0, 0x1f, 60, 0x5b, 0x79, 0x98, 0xb6, 0xd5, 0xf4, 0x112, 0x131, 0x14f, 0x16e ];

  
  //
  // start day for each month for a 365 day year, valid indices are 0..12
  //
  private static var DaysToMonth365:Array = [ 0, 0x1f, 0x3b, 90, 120, 0x97, 0xb5, 0xd4, 0xf3, 0x111, 0x130, 0x14e, 0x16d ];

  //
  // for comparisons...a Minimum and Maximum date time instances
  //
  public static var MinValue:KDateTime = new KDateTime( 0 );

  public static var MaxValue:KDateTime = new KDateTime( 0x2bca2875f4373fff );
  
  //
  // Day of week as returned by certain functions / properties e.g. DayOfWeek !
  //
  
  public static const Sunday:int   = 0;
  public static const Monday:int   = 1;
  public static const Tuesday:int  = 2;
  public static const Wednesday:int  = 3;
  public static const Thursday:int  = 4;
  public static const Friday:int   = 5;
  public static const Saturday:int  = 6;

  //
  // constructors
  //
  public function KDateTime( t:Number ) : void
  {
   // directly from ticks, ensure no fractional part has sneaked in
   
   this.ticks = Math.floor( t );
  }
  
  //
  // Construct a date time from ticks, same as default ctor
  //
  public static function FromT( t:Number ) : KDateTime
  {
   return new KDateTime( t );
  }
  
  //
  // returns a new KDateTime based on the UTC time of the given flash date object
  //
  public static function FromFlashDate( d:Date ) : KDateTime
  {
	var when:KDateTime = KDateTime.FromYMDHMSM( d.fullYearUTC,
												d.monthUTC + 1,		// .NET is month 1..12, flash is 0..11
												d.dateUTC,
												d.hoursUTC,
												d.minutesUTC,
												d.secondsUTC,
												d.millisecondsUTC);
												
	return when;
  }
  
  //
  // Construct a date time from a year, month, day
  //
  public static function FromYMD( year:int, month:int, day:int ) : KDateTime
  {
   var dt:KDateTime = new KDateTime( KDateTime.DateToTicks(year, month, day ) );
   
   return dt;
  }
  
  //
  // Construct a date time from a year, month, day, hour, minute, second
  //
  public static function FromYMDHMS( year:int, month:int, day:int, hour:int, minute:int, second:int ) : KDateTime
  {
   var dt:KDateTime = new KDateTime( KDateTime.DateToTicks(year, month, day ) + KDateTime.TimeToTicks( hour, minute, second ) );
   
   return dt;
  }
  
  //
  // Construct a date time from a year, month, day, hour, minute, second, millisecond
  //
  public static function FromYMDHMSM( year:int, month:int, day:int, hour:int, minute:int, second:int, ms:int ) : KDateTime
  {
   var dt:KDateTime = new KDateTime( KDateTime.DateToTicks(year, month, day ) + KDateTime.TimeToTicks( hour, minute, second ) );
   
   if (( ms < 0) || (ms >= 0x3e8))
        {
             throw new ArgumentError( "Argument our of range in KDateTimeFromYMDHMSM" );
        }
        
        dt.ticks += ms * 0x2710;
        
        if ((dt.ticks < 0) || (dt.ticks > 0x2bca2875f4373fff))
        {
             throw new ArgumentError( "Argument our of range in KDateTimeFromYMDHMSM" );
        }
        
   return dt;
  }
  
  //
  // private / protected methods
  //
  public static function DateToTicks( year:int, month:int, day:int ) : Number
  {
   if (((year >= 1) && (year <= 0x270f)) && ((month >= 1) && (month <= 12)))
     {
    var numArray1:Array = KDateTime.IsLeapYear(year) ? KDateTime.DaysToMonth366 : KDateTime.DaysToMonth365;
    
    if ((day >= 1) && (day <= (numArray1[month] - numArray1[month - 1])))
    {
        var num1:int = year - 1;
        
        var r1:int = num1 * 0x16d;
                
        var r2:int = num1 / 4;
        
        var r3:int = num1 / 100;
        
        var r4:int = num1 / 400;
        
        // The original expression below is broken into int components first to avoid roun off / up errors with Number type
        //
        // var num2:int = ((((((num1 * 0x16d) + (num1 / 4)) - (num1 / 100)) + (num1 / 400)) + numArray1[month - 1]) + day) - 1;
     	//
     
          var num2:int = (((((( r1 ) + r2 ) - r3 ) +  r4 ) + numArray1[month - 1]) + day) - 1;
          
          return (num2 * 0xc92a69c000);
    }
  }
        
      throw new ArgumentError("Bad Year/Month/Day");
  }
  
  //
  // Converts a time to equivalent ticks
  //
  private static function TimeToTicks( hour:int, minute:int, second:int ) : Number
  {
        if ((((hour < 0) || (hour >= 0x18)) || ((minute < 0) || (minute >= 60))) || ((second < 0) || (second >= 60)))
        {
             throw new ArgumentError( "Bad Hour/Minute/Second" );
        }
        
        return KTimeSpan.TimeToTicks(hour, minute, second);
  }
  
  //
  // true if integer year is leap year
  //
  public static function IsLeapYear( year:int ) : Boolean
  {
   // year must be divisible by 4 to be a leap year....
   
   if ((year % 4) != 0)
      return false;
    
     // except every 100 years....
     if ((year % 100) == 0)
      // unless it a multiple of 400 years e.g. 2000
        return ((year % 400) == 0);
    
     // a regular leap year
     
     return true;
  }
  
  //
  // Year property
  //
  public function get Year() : int
  {
   return this.GetDatePart( 0 );
  }
  
  //
  // Month property
  //
  public function get Month() : int
  {
   return this.GetDatePart( 2 );
  }
  
  //
  // day property
  //
  public function get Day() : int
  {
   return this.GetDatePart( 3 );
  }
  
  //
  // day of year
  //
  public function get DayOfYear() : int
  {
   return this.GetDatePart( 1 );
  }
  
  //
  // One of the Day of week constants, Sunday is 0, Monday is 1 etc
  //
  public function get DayOfWeek() : int
  {
  	return  (int) ( ( ( this.ticks / 0xc92a69c000 ) + 1 ) % 7 );
  }

  //
  // Hour of day
  //
    
  public function get Hour() : int
  {
            return (int) ( (this.ticks / 0x861c46800) % 0x18 );
  }
  
  //
  // Second component
  //
  public function get Second() : int
  {
   return (int)( ( this.ticks / 0x989680 ) % 60 );
       }

  //
  // Minutes component
  //
  public function get Minute() : int
  {
   return (int) ( ( this.ticks / 0x23c34600 ) % 60 );
  }
  
  
  //
  // extract various parts of the date component
  // 0: gets year
  // 1: day of year
  // 2: month
  // 3: day
  private function GetDatePart( part:int ) : int
  {
        var num1:int = (int) (this.ticks / 0xc92a69c000);
        var num2:int = num1 / 0x23ab1;
        num1 -= num2 * 0x23ab1;
        var num3:int = num1 / 0x8eac;
        if (num3 == 4)
        {
              num3 = 3;
        }
        num1 -= num3 * 0x8eac;
        var num4:int = num1 / 0x5b5;
        num1 -= num4 * 0x5b5;
        var num5:int = num1 / 0x16d;
        if (num5 == 4)
        {
              num5 = 3;
        }
        if (part == 0)
        {
              return (((((num2 * 400) + (num3 * 100)) + (num4 * 4)) + num5) + 1);
        }
        num1 -= num5 * 0x16d;
        if (part == 1)
        {
              return (num1 + 1);
        }
        var numArray1:Array = ((num5 == 3) && ((num4 != 0x18) || (num3 == 3))) ? KDateTime.DaysToMonth366 : KDateTime.DaysToMonth365;
        
        var num6:int = num1 >> 6;
        
        while (num1 >= numArray1[num6])
        {
              num6++;
        }
        if (part == 2)
        {
              return num6;
        }
        return ((num1 - numArray1[num6 - 1]) + 1);
  }
  
  //
  // Return number of days in month for the given year
  //
  public static function DaysInMonth( year:int, month:int ) : int
  {
        if ((month < 1) || (month > 12))
        {
             throw new ArgumentError( "Argument Out Of Range Month" );
        }
        
        var numArray1:Array = KDateTime.IsLeapYear(year) ? KDateTime.DaysToMonth366 : KDateTime.DaysToMonth365;
        
        return (numArray1[month] - numArray1[month - 1]);
  }
  
  //
  // add a value with a given scaling. Underpins most of the .Add methods
  //
  private function Add( value:Number, scale:int ) : KDateTime
  {
        var num1:Number = Math.floor( ((value * scale) + ((value >= 0) ? 0.5 : -0.5)) );
        
        if ((num1 <= -315537897600000) || (num1 >= 0x11efae44cb400))
        {
             throw new ArgumentError( "Argument Out Of Range in KDateTime:AddValue" );
        }
        
        return new KDateTime( this.ticks + (num1 * 0x2710) );
  }
  
  //
  // subtract given number of ticks from this. Clamps to limits
  //
  public function Subtract( ticks:Number ) : void
  {
  	this.ticks = Math.max( KDateTime.MinValue.ticks, Math.min( KDateTime.MaxValue.ticks, this.ticks - ticks ) );
  }
  
  //
  // Add given number of days and return a new instance
  // 
  public function AddDays( value:Number ) : KDateTime
  {
   return this.Add( value, 0x5265c00 );
  }
  
  //
  // add given hours
  //
  public function AddHours( value:Number ) : KDateTime
  {
   return this.Add(value, 0x36ee80);
  }
  
  //
  // add given minutes
  //
  public function AddMinutes( value:Number ) : KDateTime
  {
   return this.Add(value, 0xea60);
  }
  
  //
  // add given seconds
  //
  public function AddSeconds( value:Number ) : KDateTime
  {
   return this.Add(value, 0x3e8 );
  }
  
  //
  // add given MS
  //
  public function AddMilliseconds( value:Number ) : KDateTime
  {
	  return this.Add(value, 1 );
  }
  
  //
  // add given ticks
  //
  public function AddTicks( value:Number ) : KDateTime
  {
   return new KDateTime( this.ticks + value );
  }
  
  //
  // add given number of years
  //
  public function AddYears( value:int ) : KDateTime
  {
        return this.AddMonths(value * 12);
  }

  //
  // Add number of months, tricky since you need to know how many leap years are involved
  //
  public function AddMonths( months:int ) : KDateTime
  {
        if ((months < -120000) || (months > 0x1d4c0))
        {
              throw new ArgumentError( "Argument Out Of Range, Bad Months" );
        }
        var num1:int = this.GetDatePart(0);
        var num2:int = this.GetDatePart(2);
        var num3:int = this.GetDatePart(3);
        var num4:int = (num2 - 1) + months;
        if (num4 >= 0)
        {
              num2 = (num4 % 12) + 1;
              num1 += num4 / 12;
        }
        else
        {
              num2 = 12 + ((num4 + 1) % 12);
              num1 += (num4 - 11) / 12;
        }
        var num5:int = KDateTime.DaysInMonth(num1, num2);
        if (num3 > num5)
        {
              num3 = num5;
        }
        return new KDateTime( KDateTime.DateToTicks(num1, num2, num3) + (this.ticks % 0xc92a69c000));
  }
  
	  //
	  // Return as formatted string. The format string is a series of codes seperated by '%' characters. Some codes are followed by parameters.
	  // Codes are case sensitive.
	  //
	  // Codes and parameters:
	  //
	  // %lt[literal string]	, indicates literal string to include in output.
	  // %dm					, day of the month as integer ( 1..31 )
	  // %DM					, day of the month followed by appropriate suffix e.g. 21st, 13th, 1st, 23rd
	  // %dw					, day of the week e.g. Sunday, Monday etc.
	  // %DW					, short day of the week e.g. Sun, Mon, Tue, Wed, Thu, Fri, Sat, Sun
	  // %mm					, month as an integer ( 1..12 )
	  // %MM					, month as name e.g. January, Feburary etc.
	  // %SM					, month as short name e.g. Jan, Feb etc
	  // %yy					, year as integer ( 0000 )
	  // %hh					, hour as integer, 12 hour format 1,2,3,4,5,6,7,8,9,10,11,12
	  // %HH					, hour as integer, 24 hour format 01,02,03...23
	  // %mi					, minutes of hour ( 00 )
	  // %si					, seconds as integer ( 00 )
	  // %ap					, am or pm
	  // %AP					, AM or PM
	  // %sd					, short date format mm/dd/yyyy
	  // %st					, short time hh:mm:ss am/pm ( seconds omitted if zero )
	  //
	  // e.g "%DW%lt the %DM%lt of %SM%lt %yy"
	  //
	  // produces: "Mon the 27th of Jul 1964"
	  //
	  public function Format( f:String ) : String
	  {
	  	// output string
	  	
	  	var output:String = "";
	  	
	  	// split into discreet code sections
	  	
	  	var sections:Array = f.split( "%" );
	  	
	  	// BUG: Split always seems to return a empty first element in the array, we ignore it
	  	
	  	// process each section
	  	
	  	for each( var s:String in sections )
	  	{
	  		var code:String = s.substr( 0, 2 );
	  		
	  		switch( code )
	  		{
	  			case "lt" : 
	  			{	
	  				// literal string
	  				
	  				output += s.substr( 2 );
	  				
	  			} break;
	  			
	  			case "mm" :
	  			{
	  				// month as integer
	  				
	  				output += this.Month.toString();
	  				
	  			} break;
	  			
	  			case "MM" :
	  			{
	  				
	  				switch( this.Month )
	  				{
	  					case 1: output += "January"; break;
	  					case 2: output += "Febuary"; break;
	  					case 3: output += "March"; break;
	  					case 4: output += "April"; break;
	  					case 5: output += "May"; break;
	  					case 6: output += "June"; break;
	  					case 7: output += "July"; break;
	  					case 8: output += "August"; break;
	  					case 9: output += "September"; break;
	  					case 10: output += "October"; break;
	  					case 11: output += "November"; break;
	  					case 12: output += "December"; break;

	  				}
	  				
	  			} break;

	  			case "SM" :
	  			{
	  				
	  				switch( this.Month )
	  				{
	  					case 1: output += "Jan"; break;
	  					case 2: output += "Feb"; break;
	  					case 3: output += "Mar"; break;
	  					case 4: output += "Apr"; break;
	  					case 5: output += "May"; break;
	  					case 6: output += "Jun"; break;
	  					case 7: output += "Jul"; break;
	  					case 8: output += "Aug"; break;
	  					case 9: output += "Sep"; break;
	  					case 10: output += "Oct"; break;
	  					case 11: output += "Nov"; break;
	  					case 12: output += "Dec"; break;

	  				}
	  				
	  			} break;
	  			
	  			case "dm" : 
	  			{
	  				// day of month as integer
	  				
	  				output += this.Day.toString();
	  				
	  			} break;
	  			
	  			case "DM" : 
	  			{
	  				// day of month as integer
	  				
	  				output += KDateTime.GetIndexString( this.Day );
	  				
	  			} break;
	  			
	  			case "yy" :
	  			{
	  				// year
	  				
	  				output += this.Year.toString();
	  				
	  			} break;
	  			
	  			case "dw" :
	  			{
	  				// day of the week long
	  				
	  				switch ( this.DayOfWeek )
	  				{
	  					case 0: output += "Sunday" ; break;
	  					case 1: output += "Monday" ; break;
	  					case 2: output += "Tuesday" ; break;
	  					case 3: output += "Wednesday" ; break;
	  					case 4: output += "Thursday" ; break;
	  					case 5: output += "Friday" ; break;
	  					case 6: output += "Saturday" ; break;
	  				}
	  			} break;
	  			
	  			case "DW" :
	  			{
	  				// day of the week short
	  				
	  				switch ( this.DayOfWeek )
	  				{
	  					case 0: output += "Sun" ; break;
	  					case 1: output += "Mon" ; break;
	  					case 2: output += "Tue" ; break;
	  					case 3: output += "Wed" ; break;
	  					case 4: output += "Thu" ; break;
	  					case 5: output += "Fri" ; break;
	  					case 6: output += "Sat" ; break;
	  				}
	  				
	  			} break;
	  			
	  			case "hh" : 
	  			{
	  				// hour 12 hour format
	  				
	  				var h:int = this.Hour;

					if ( h == 0 || h == 12 )
						output += "12";
					else
						output += ( this.Hour % 12 ).toString();
	  				
	  			} break;
	  			
	  			case "HH" : 
	  			{
	  				// hour 24 hour format, always 2 digits
	  				
					var temp:String = this.Hour.toString();
					
					if ( temp.length < 2 )
						temp = "0" + temp;
						
					output += temp;
	  				
	  			} break;
	  			
	  			case "mi" : 
	  			{
	  				// minutes always 2 digits
	  				
					temp = this.Minute.toString();
					
					if ( temp.length < 2 )
						temp = "0" + temp;
						
					output += temp;
	  				
	  			} break;
	  			
	  			case "si" : 
	  			{
	  				// seconds always 2 digits
	  				
					temp = this.Second.toString();
					
					if ( temp.length < 2 )
						temp = "0" + temp;
						
					output += temp;
	  				
	  			} break;
	  			
	  			case "ap" : 
	  			{
	  				// lower case am or pm
	  				
	  				if ( this.Hour < 12 )
	  					output += "am";
	  				else
	  					output += "pm";
	  				
	  				
	  			} break;
	  			
	  			case "AP" : 
	  			{
	  				// upper case am or pm
	  				
	  				if ( this.Hour < 12 )
	  					output += "AM";
	  				else
	  					output += "PM";
	  				
	  				
	  			} break;
	  			
	  			case "sd" : 
	  			{
					output += 	this.Month.toString() + "/" + 
								this.Day.toString() + "/" + 
								this.Year.toString();
	  				
	  				
	  			} break;
	  			
	  			case "st" : 
	  			{	
	  				// hour 24 hour format, always 2 digits
	  				
					var hour:String = this.Hour.toString();
					
					if ( hour.length < 2 )
						hour = "0" + hour;
						
					var minute:String = this.Minute.toString();
					
					if ( minute.length < 2 )
						minute = "0" + minute;
						
					var seconds:String = "";
					
					if ( this.Second > 0 )
					{
						seconds = this.Second.toString();
						
						if ( seconds.length < 2 )
							seconds = "0" + seconds;
							
						seconds = ":" + seconds;
					}
					
					output += hour + ":" + minute + seconds;
	  				
	  			} break;
	  			

	  		}	
	  	}
	  		
	  	return output;
	  }
	  
	  		/// <summary>
		/// Returns the appropriate representation of numbers in the range 1..31 
		/// e.g 1 = "1st", 2 = "2nd", 11 = "11th", 31 = "31st", 0 = "0th"
		/// </summary>
		/// <param name="?"></param>
		/// <returns></returns>
		public static function GetIndexString( v:int ) : String
		{
			// rules are different < 20

			if ( v < 20 )
				return v.toString() + KDateTime.under20[ v ];

			return v.toString() + KDateTime.over20[ v % 10 ];	
		}

		protected static var under20:Array =
		[
			"th",	// 0th
			"st",	// 1st
			"nd",	// 2nd
			"rd",	// 3rd
			"th",	// 4th
			"th",	// 5th
			"th",	// 6th	
			"th",	// 7th
			"th",	// 8th
			"th",	// 9th
			"th",	// 10th
			"th",	// 11th
			"th",	// 12th
			"th",	// 13th
			"th",	// 14th
			"th",	// 15th
			"th",	// 16th	
			"th",	// 17th
			"th",	// 18th
			"th",	// 19th
		]

		protected static var over20:Array = 
		[
			"th",	// 20th
			"st",	// 21st
			"nd",	// 22nd
			"rd",	// 23rd
			"th",	// 24th
			"th",	// 25th
			"th",	// 26th
			"th",	// 27th	
			"th",	// 28th
			"th",	// 29th
		];
  
  //
  // a long but precise form of date time e.g. Mon the 27th of July 1964 10:30am
  //
  public function ToLongDateTimeString() : String
  {
  	return this.Format( "%DW%lt the %DM%lt of %SM%lt %yy%lt %hh%lt:%mi%ap" );
  }
  
  public function ToReallyLongDateTimeString() : String
  {
	  return this.Format( "%DW%lt the %DM%lt of %SM%lt %yy%lt %hh%lt:%mi%lt:%si" );
  }
  
  //
  // return a short date time string
  //
  public function ToShorKDateTime() : String
  {
  	// for date part, show Today, Yesterday, or day or week if within 7 days of now
  	
  	var now:KDateTime = KDateTime.Now;
  	
  	var dateStr:String;
  	
  	// calculate if today or within 7 days
  	
  	var today:Boolean = now.Year == this.Year && now.Month == this.Month && now.Day == this.Day;
  	
  	var lastSevenDays:Boolean = ( this.Ticks < now.Ticks ) && ( now.Ticks - this.Ticks ) <= ( KTimeSpan.TicksPerDay * 7 );
  	
  	if ( today || lastSevenDays  )
  	{
  		if ( today == true )
  			dateStr = "Today";
  		else
 			dateStr = this.Format( "%dw" );
  	}
  	else
  		dateStr = this.Format( "%mm%lt/%dm%lt/%yy" );
  	
  	// append a space and the time
  	
  	return dateStr + " " + this.Format("%hh%lt:%mi%ap");
  }
  
  public function toString() : String
  {
   var s:String =  "KDateTime for:" + this.Year + "-" + this.Month + "-" + this.Day;
   
   return s;
  }
 }
}