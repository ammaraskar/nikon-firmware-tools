/*
 * AssemblerFrTokenMaker.java - An object that can take a chunk of text and
 * return a linked list of tokens representing Fujitsu Fr assembler.
 * Based on AssemblerX86TokenMaker.java by Robert Futrell
 */
package com.nikonhacker.gui.component.sourceCode.syntaxHighlighter;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * This class takes plain text and returns tokens representing Fr
 * assembler.<p>
 *
 * This implementation was created using
 * <a href="http://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>, so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated AssemblerFrTokenMaker.java</code> file will contain two
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 * @author Robert Futrell
 * @version 0.2
 *
 */
%%

%public
%class AssemblerFrTokenMaker
%extends AbstractJFlexTokenMaker
%implements TokenMaker
%unicode
%ignorecase
%type org.fife.ui.rsyntaxtextarea.Token


%{


	/**
	 * Constructor.  We must have this here as JFLex does not generate a
	 * no parameter constructor.
	 */
	public AssemblerFrTokenMaker() {
		super();
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *                    occurs.
	 */
	public void addToken(char[] array, int start, int end, int tokenType, int startOffset) {
		super.addToken(array, start,end, tokenType, startOffset);
		zzStartRead = zzMarkedPos;
	}


	/**
	 * Returns the text to place at the beginning and end of a
	 * line to "comment" it in a this programming language.
	 *
	 * @return The start and end strings to add to a line to "comment"
	 *         it out.
	 */
	public String[] getLineCommentStartAndEnd() {
		return new String[] { ";", null };
	}


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *                    <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		// Start off in the proper state.
		int state = Token.NULL;
		switch (initialTokenType) {
			default:
				state = Token.NULL;
		}

		s = text;
		try {
			yyreset(zzReader);
			yybegin(state);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new DefaultToken();
		}

	}

	/**
	 * Returns whether tokens of the specified type should have "mark
	 * occurrences" enabled for the current programming language.
	 * Basically, we return true for everything except blanks
	 *
	 * @param type The token type.
	 * @return Whether tokens of this type should have "mark occurrences"
	 *         enabled.
	 */
	public boolean getMarkOccurrencesOfTokenType(int type) {
        return     type == Token.IDENTIFIER
                || type == Token.FUNCTION
                || type == Token.RESERVED_WORD
                || type == Token.RESERVED_WORD_2
                || type == Token.DATA_TYPE
                || type == Token.LITERAL_CHAR
                || type == Token.LITERAL_NUMBER_HEXADECIMAL
                || type == Token.ANNOTATION
                || type == Token.OPERATOR
                || type == Token.VARIABLE;
	}


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 * @exception   IOException  if any I/O-Error occurs.
	 */
	private boolean zzRefill() throws java.io.IOException {
		return zzCurrentPos>=s.offset+s.count;
	}


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream 
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream 
	 */
	public final void yyreset(java.io.Reader reader) throws java.io.IOException {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}

Letter				= ([A-Za-z_])
Digit				= ([0-9])
HexDigit			= ({Digit}|[A-Fa-f])
/*Number				= ({Digit}+)*/

Address             = ({HexDigit}{HexDigit}{HexDigit}{HexDigit}{HexDigit}{HexDigit}{HexDigit}{HexDigit})
Instruction         = ({HexDigit}{HexDigit}{HexDigit}{HexDigit})
Identifier			= ({Letter}({Letter}|{Digit})[^ \t\f\n\,\.\+\-\*\/\%\[\]]+)

UnclosedStringLiteral	= ([\"][^\"]*)
StringLiteral			= ({UnclosedStringLiteral}[\"])
UnclosedCharLiteral		= ([\'][^\']*)
CharLiteral			= ({UnclosedCharLiteral}[\'])

CommentBegin			= ([;])

LineTerminator			= (\n)
WhiteSpace			= ([ \t\f])

Label				= (({Letter}|{Digit})+[\:])

Operator				= ("+"|"-"|"*"|"/"|"%"|"^"|"|"|"&"|"~"|"!"|"="|"<"|">")

%%

<YYINITIAL> {


"ADD" |
"ADD2" |
"ADDC" |
"ADDN" |
"ADDN2" |
"ADDSP" |
"AND" |
"ANDB" |
"ANDCCR" |
"ANDH" |
"ASR" |
"ASR2" |
"BANDH" |
"BANDL" |
"BEORH" |
"BEORL" |
"BORH" |
"BORL" |
"BTSTH" |
"BTSTL" |
"CMP" |
"CMP2" |
"COPLD" |
"COPOP" |
"COPST" |
"COPSV" |
"DIV0S" |
"DIV0U" |
"DIV1" |
"DIV2" |
"DIV3" |
"DIV4S" |
"DMOV" |
"DMOVB" |
"DOVH" |
"ENTER" |
"EOR" |
"EORB" |
"EORH" |
"EXTSB" |
"EXTSH" |
"EXTUB" |
"EXTUH" |
"INT" |
"INTE" |
"LD" |
"LD" |
"LDI:20" |
"LDI:32" |
"LDI:8" |
"LDM0" |
"LDM1" |
"LDRES" |
"LDUB" |
"LDUH" |
"LEAVE" |
"LSL" |
"LSL2" |
"LSR" |
"LSR2" |
"MOV" |
"MUL" |
"MULH" |
"MULU" |
"MULUH" |
"NOP" |
"OR" |
"ORB" |
"ORCCR" |
"ORH" |
"POP" |
"PUSH" |
"ST" |
"STB" |
"STH" |
"STILM" |
"STM0" |
"STM1" |
"STRES" |
"STUB" |
"STUH" |
"SUB" |
"SUBC" |
"SUBN" |
"XCHB"		{ addToken(Token.RESERVED_WORD); }


"BC" |
"BC:D" |
"BEQ" |
"BEQ:D" |
"BGE" |
"BGE:D" |
"BGT" |
"BGT:D" |
"BHI" |
"BHI:D" |
"BLE" |
"BLE:D" |
"BLS" |
"BLS:D" |
"BLT" |
"BLT:D" |
"BN" |
"BN:D" |
"BNC" |
"BNC:D" |
"BNE" |
"BNE:D" |
"BNO" |
"BNO:D" |
"BNV" |
"BNV:D" |
"BP" |
"BP:D" |
"BRA" |
"BRA:D" |
"BV" |
"BV:D" |
"CALL" |
"CALL:D" |
"JMP" |
"JMP:D" |
"RET" |
"RET:D" |
"RETI"      { addToken(Token.RESERVED_WORD_2); }


	"DB" |
	"DW" |
	"DD" |
	"DF" |
	"DQ" |
	"DT"	{ addToken(Token.FUNCTION); }

	"BYTE" |
	"WORD" |
	"DWORD" |
	"FWORD" |
	"QWORD" |
	"TBYTE" |
	"SBYTE" |
	"TWORD" |
	"SWORD" |
	"SDWORD" |
	"REAL4" |
	"REAL8" |
	"REAL10"		{ addToken(Token.DATA_TYPE); }

	/* Registers */
	"AC" |
"CCR" |
"FP" |
"ILM" |
"MD" |
"MDH" |
"MDL" |
"PC" |
"PS" |
"R0" |
"R1" |
"R10" |
"R11" |
"R12" |
"R13" |
"R14" |
"R15" |
"R2" |
"R3" |
"R4" |
"R5" |
"R6" |
"R7" |
"R8" |
"R9" |
"RP" |
"SCR" |
"SP" |
"SSP" |
"TBR" |
"USP"		{ addToken(Token.VARIABLE); }

}

<YYINITIAL> {

	{LineTerminator}				{ addNullToken(); return firstToken; }

	{WhiteSpace}+					{ addToken(Token.WHITESPACE); }

	/* String/Character Literals. */
	{CharLiteral}					{ addToken(Token.LITERAL_CHAR); }
	{UnclosedCharLiteral}			{ addToken(Token.ERROR_CHAR); /*addNullToken(); return firstToken;*/ }
	{StringLiteral}				{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{UnclosedStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }

	/* Labels. */
	{Label}						{ addToken(Token.PREPROCESSOR); }

	{Address}                       { addToken(Token.LITERAL_NUMBER_HEXADECIMAL); }
	{Instruction}                       { addToken(Token.ANNOTATION); }


	/* Comment Literals. */
	{CommentBegin}.*				{ addToken(Token.COMMENT_EOL); addNullToken(); return firstToken; }

	/* Operators. */
	{Operator}					{ addToken(Token.OPERATOR); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>						{ addNullToken(); return firstToken; }

	/* Catch any other (unhandled) characters. */
	{Identifier}					{ addToken(Token.IDENTIFIER); }
	.							{ addToken(Token.IDENTIFIER); }

}
