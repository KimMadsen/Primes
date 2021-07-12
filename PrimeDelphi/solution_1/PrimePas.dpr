program PrimePas;

// Optimized by Kim Madsen/C4D
// www.components4developers.com

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Classes,
  System.Generics.Collections,
  System.Timespan,
  Math,
  Windows;

var
	MyDict : TDictionary<NativeInt, NativeInt>;

type

	TPrimeSieve = class
	private
		FSieveSize: NativeInt;
		FSieveSize2: NativeInt;
		FSieveSizeSqrt: NativeInt;
		FBitArray: array of ByteBool;

	public
		constructor Create(Size: Integer);

		procedure RunSieve; // Calculate the primes up to the specified limit

		function CountPrimes: Integer;
		function ValidateResults: Boolean;

		procedure PrintResults(ShowResults: Boolean; Duration: Double; Passes: Integer);
	end;

{ TPrimeSieve }

constructor TPrimeSieve.Create(Size: Integer);
begin
	inherited Create;

	FSieveSize := Size;
	FSieveSize2:= (Size+1) div 2;
	FSieveSizeSqrt:=Floor(Sqrt(FSieveSize));

	//The optimization here is that we only store bits for *odd* numbers.
	// So FBitArray[3] is if 3 is prime
	// and FBitArray[4] is if 5 is prime
	SetLength(FBitArray, FSieveSize2);
end;

function TPrimeSieve.CountPrimes: Integer;
var
	i: NativeInt;
begin
	Result := 0;
	for i := 0 to High(FBitArray) do
   	if (not FBitArray[i]) then Inc(Result);  // remember logic is reversed
end;

function TPrimeSieve.ValidateResults: Boolean;
begin
	if MyDict.ContainsKey(FSieveSize) then
		Result := MyDict[FSieveSize] = Self.CountPrimes
	else
		Result := False;
end;

procedure TPrimeSieve.RunSieve;
var
	num: NativeInt;
	r: NativeInt;
	factor: NativeInt;
begin
	factor := 3;

	while factor<=FSieveSizeSqrt do
	begin
		r:=factor AND $1;
		num:=factor SHR 1;
		while num<FSieveSizeSqrt do
		begin
			if (not FBitArray[num]) then   // logic is reversed to avoid initializer
			begin
				factor := (num SHL 1) OR r;
				Break;
			end;
			inc(num);
		end;

		// If marking factor 3, you wouldn't mark 6 (it's a mult of 2) so start with the 3rd instance of this factor's multiple.
		num := factor*3 SHR 1;
		while num<=FSieveSize2 do
		begin
			FBitArray[num]:=true;  // logic is reversed.
			Inc(num,factor);
		end;

		Inc(factor,2);
	end;
end;

procedure TPrimeSieve.PrintResults(ShowResults: Boolean; Duration: Double; Passes: Integer);
var
	count: Integer;
	num: Integer;
const
	SYesNo: array[Boolean] of string = ('No', 'Yes');
begin
	if ShowResults then
		Write('2, ');

	count := 1;
	for num := 3 to FSieveSize do
	begin
		if (num and $1 = $1) then
		begin
			if not FBitArray[num div 2] then
			begin
				if ShowResults then
					Write(IntToStr(num) + ', ');
				Inc(count);
			end;
		end;
	end;

	if ShowResults then
		WriteLn('');

	WriteLn(Format('Passes: %d, Time: %.3f sec, Avg: %.4f ms, Limit: %d, Count: %d, Valid: %s',
		[Passes, Duration, Duration/Passes*1000, FSieveSize, count, SYesNo[ValidateResults]]));
end;

procedure Main;
var
	sieve: TPrimeSieve;
	dtStart: TDateTime;
	passes: Integer;
	tD: TTimeSpan;
begin
	dtStart := Now;
	passes := 0;

	sieve := nil;
	while TTimeSpan.Subtract(Now, dtStart).TotalSeconds < 5 do
	begin
		if Assigned(sieve) then
			sieve.Free;

		sieve := TPrimeSieve.Create(1000000);
		sieve.RunSieve;
		Inc(passes);
	end;

	tD := TTimeSpan.Subtract(Now, dtStart);
	if Assigned(sieve) then
		sieve.PrintResults(False, tD.TotalSeconds, passes);
end;

Procedure InitStaticDictionary;
begin
	MyDict := TDictionary<NativeInt, NativeInt>.Create;

	// Historical data for validating our results - the number of primes
	// to be found under some limit, such as 168 primes under 1000
	MyDict.Add(       10, 4); //nobody noticed that 1 is wrong? [2, 3, 5, 7]
	MyDict.Add(      100, 25);
	MyDict.Add(     1000, 168);
	MyDict.Add(    10000, 1229);
	MyDict.Add(   100000, 9592);
	MyDict.Add(  1000000, 78498);
	MyDict.Add( 10000000, 664579);
	MyDict.Add(100000000, 5761455);
end;

{
	Intel Core i5-9400 @ 2.90 GHz
	- 32-bit: 4,809 passes
	- 64-bit: 2,587 passes


  Pre optimization by Kim Madsen/C4D
  (plenty of other CPU heavy processes running on various cores)
  AMD Threadripper 1950X @ 3.40 GHz
	- 32-bit: 4,400 passes

  Post optimization by Kim Madsen/C4D
  (plenty of other CPU heavy processes running on various cores)
  AMD Threadripper 1950X @ 3.40 GHz
  - 32-bit: 7,600 passes
  - 64-bit: DEAD SLOW of some reason
  Further optimizations:
  - 32-bit: 8,600+ passes

  Optimization of Kim's code by glenkleidon
  - Made the History class static (as it is in the c++ because define as a const)
  - The initializer for Delphi ByteBool by default sets to false
    previous implementation initialized every value to true first,
    but a better optimization is to simply reverse the logic - false = true/
     true=false so there is no need to initialize the array.
    Techically Delphi could have used a call to
       FillChar(FBitArray[0],FSieveSize2,1);
    but dynamic arrays MAY not be contiguous and therefore not safe.
}
begin
	try
    InitStaticDictionary;
		Main;
		WriteLn('Press enter to close...');
		Readln;
	except
		on E: Exception do
			Writeln(E.ClassName, ': ', E.Message);
	end;
end.
