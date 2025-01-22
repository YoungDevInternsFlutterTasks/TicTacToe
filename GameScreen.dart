import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  final bool isSinglePlayer;
  const GameScreen({super.key, required this.isSinglePlayer});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late List<List<String>> board;
  late bool xTurn;
  late bool GameOver;
  late String Winner;
  bool isComputerThinking = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    initializeGame();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void initializeGame() {
    board = List.generate(3, (_) => List.filled(3, ''));
    xTurn = true;
    GameOver = false;
    Winner = '';
    isComputerThinking = false;
  }

  void showGameOverDialog() {
    _animationController.forward(from: 0.0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth > 400 ? 400.0 : screenWidth * 0.9;

        return ScaleTransition(
          scale: _scaleAnimation,
          child: AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.all(20),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                minHeight: 200,
                maxHeight: 400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Winner == 'Draw'
                          ? Colors.orange.withOpacity(0.2)
                          : Winner == 'X'
                              ? const Color.fromARGB(255, 0, 0, 128)
                                  .withOpacity(0.2)
                              : const Color.fromARGB(255, 47, 79, 79)
                                  .withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        Winner == "Draw"
                            ? Icons.balance
                            : Winner == "X"
                                ? Icons.close
                                : Icons.circle_outlined,
                        size: 50,
                        color: Winner == "Draw"
                            ? Colors.orange
                            : Winner == "X"
                                ? Color.fromARGB(255, 0, 0, 128)
                                : Color.fromARGB(255, 47, 79, 79)),
                  ),
                  SizedBox(height: 20),
                  Text(
                    Winner == "Draw"
                        ? "It's a Draw!"
                        : Winner == "X"
                            ? widget.isSinglePlayer
                                ? "You Won!"
                                : "Player X Wins!"
                            : widget.isSinglePlayer
                                ? "Computer Wins!"
                                : "Player O Wins!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Winner == "Draw"
                            ? Colors.orange
                            : Winner == "X"
                                ? const Color.fromARGB(255, 0, 0, 128)
                                : const Color.fromARGB(255, 47, 79, 79)),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            initializeGame();
                          });
                        },
                        child: Text(
                          'Play Again!',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Main Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void makeMove(int row, int col) {
    // Prevent move if the cell is not empty, the game is over, or the computer is thinking
    if (board[row][col] != '' || GameOver || isComputerThinking) return;

    setState(() {
      // Player's move
      board[row][col] = xTurn ? 'X' : 'O';
      checkWinner(row, col);
      xTurn = !xTurn;

      // If single-player and it's the computer's turn, trigger computer's move
      if (widget.isSinglePlayer && !xTurn && !GameOver) {
        isComputerThinking = true;
        Timer(Duration(seconds: 1), () {
          if (!mounted) return;
          computerMove();
        });
      }
    });
  }

  void computerMove() {
    // Find a move for the computer
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == '') {
          board[i][j] = 'O';
          if (checkWinningMove(i, j, 'O')) {
            setState(() {
              checkWinner(i, j);
              xTurn = !xTurn;
              isComputerThinking = false;
            });
            return;
          }
          board[i][j] = '';
        }
      }
    }

    // If no winning move, make a random move
    List<List<int>> emptyCells = [];
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == '') {
          emptyCells.add([i, j]);
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final random = Random();
      final move = emptyCells[random.nextInt(emptyCells.length)];
      setState(() {
        board[move[0]][move[1]] = 'O';
        checkWinner(move[0], move[1]);
        xTurn = !xTurn;
        isComputerThinking = false;
      });
    }
  }

  bool checkWinningMove(int row, int col, String player) {
    //check row
    if (board[row].every((cell) => cell == player)) return true;

    //check column
    if (board.every((row) => row[col] == player)) return true;

    //check diagonals
    if (row == col) {
      if (List.generate(3, (i) => board[i][i])
          .every((cell) => cell == player)) {
        return true;
      }
    }
    if (row + col == 2) {
      if (List.generate(3, (i) => board[i][2 - i])
          .every((cell) => cell == player)) {
        return true;
      }
    }
    return false;
  }

  void checkWinner(int row, int col) {
    final currentPlayer = board[row][col];

    if (checkWinningMove(row, col, currentPlayer)) {
      GameOver = true;
      Winner = currentPlayer;
      showGameOverDialog();
      return;
    }
    if (board.every((row) => row.every((cell) => cell != ''))) {
      GameOver = true;
      Winner = "Draw";
      showGameOverDialog();
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color.fromARGB(255, 4, 158, 247),
            const Color.fromARGB(255, 224, 126, 33)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              GameOver
                  ? Winner == 'Draw'
                      ? 'Game Draw!'
                      : 'Player $Winner Wins!'
                  : isComputerThinking
                      ? 'Computer is thinking...'
                      : 'Player ${xTurn ? 'X' : 'O'}\'s Turn',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final row = index ~/ 3;
                    final col = index % 3;
                    return GestureDetector(
                      onTap: () => makeMove(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            board[row][col],
                            style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: board[row][col] == 'X'
                                    ? const Color.fromARGB(255, 0, 0, 128)
                                    : const Color.fromARGB(255, 28, 160, 160)),
                          ),
                        ),
                      ),
                    );
                  }),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      initializeGame();
                    });
                  },
                  child: Text(
                    "Restart",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Main Menu",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ))
              ],
            )
          ],
        )),
      ),
    );
  }
}
