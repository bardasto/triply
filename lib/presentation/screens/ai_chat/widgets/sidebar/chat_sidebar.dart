import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../models/chat_history.dart';
import '../../models/chat_mode.dart';
import '../../theme/ai_chat_theme.dart';
import '../common/circle_button.dart';
import 'history_item.dart';
import 'sidebar_button.dart';

/// The sidebar panel for chat navigation and history.
class ChatSidebar extends StatelessWidget {
  final Animation<double> slideAnimation;
  final ChatMode currentMode;
  final List<ChatHistory> chatHistory;
  final String? currentChatId;
  final VoidCallback onClose;
  final VoidCallback onNewChat;
  final void Function(ChatMode) onModeSelected;
  final void Function(ChatHistory) onHistorySelected;
  final void Function(ChatHistory) onHistoryDeleted;
  final void Function(DragUpdateDetails, double) onDragUpdate;
  final void Function(DragEndDetails) onDragEnd;
  final String Function(DateTime) formatDate;

  const ChatSidebar({
    super.key,
    required this.slideAnimation,
    required this.currentMode,
    required this.chatHistory,
    this.currentChatId,
    required this.onClose,
    required this.onNewChat,
    required this.onModeSelected,
    required this.onHistorySelected,
    required this.onHistoryDeleted,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * AiChatTheme.sidebarWidthFactor;

    return AnimatedBuilder(
      animation: slideAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Dimmed background
            if (slideAnimation.value < 1.0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: (1 - slideAnimation.value) * 0.5,
                    ),
                  ),
                ),
              ),
            // Panel
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: panelWidth,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) =>
                    onDragUpdate(details, panelWidth),
                onHorizontalDragEnd: onDragEnd,
                child: Transform.translate(
                  offset: Offset(panelWidth * slideAnimation.value, 0),
                  child: _buildPanelContent(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanelContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildActionButtons(),
          _buildDivider(),
          _buildHistoryHeader(),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.darkBackground,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    'Generate me',
                    style: AiChatTheme.sidebarTitle,
                  ),
                  const Spacer(),
                  CircleButton(
                    icon: CupertinoIcons.square_pencil,
                    onTap: onNewChat,
                  ),
                  const SizedBox(width: 10),
                  CircleButton(
                    icon: Icons.close,
                    onTap: onClose,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          SidebarButton(
            icon: Icons.flight_takeoff,
            label: 'Trip Generation',
            isSelected: currentMode == ChatMode.tripGeneration,
            onTap: () => onModeSelected(ChatMode.tripGeneration),
          ),
          SidebarButton(
            icon: Icons.hotel,
            label: 'Hotel Selection',
            isSelected: currentMode == ChatMode.hotelSelection,
            onTap: () => onModeSelected(ChatMode.hotelSelection),
          ),
          SidebarButton(
            icon: Icons.airplane_ticket,
            label: 'Flight Tickets',
            isSelected: currentMode == ChatMode.flightTickets,
            onTap: () => onModeSelected(ChatMode.flightTickets),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 0.5,
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'History',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    // Filter out empty chats (only welcome message)
    final nonEmptyHistory = chatHistory.where((h) => !h.isEmpty).toList();

    return Expanded(
      child: nonEmptyHistory.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Your chat history will appear here',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: nonEmptyHistory.length,
              itemBuilder: (context, index) {
                final history = nonEmptyHistory[index];
                final isSelected = history.id == currentChatId;
                return HistoryItem(
                  history: history,
                  isSelected: isSelected,
                  onTap: () => onHistorySelected(history),
                  onDelete: () => onHistoryDeleted(history),
                  formatDate: formatDate,
                );
              },
            ),
    );
  }
}
