import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class IconHelper {
  static IconData getIcon(String name) {
    switch (name) {
      case 'zap':
        return LucideIcons.zap;
      case 'droplet':
        return LucideIcons.droplet;
      case 'building':
        return LucideIcons.building;
      case 'trash':
        return LucideIcons.trash2;
      case 'box':
        return LucideIcons.box;
      case 'wifi':
        return LucideIcons.wifi;
      case 'help-circle':
        return LucideIcons.helpCircle;
      case 'lock':
        return LucideIcons.lock;
      case 'trees':
        return LucideIcons.trees;
      case 'hard-hat':
        return LucideIcons.hardHat;
      case 'file-text':
        return LucideIcons.fileText;
      case 'alert-triangle':
        return LucideIcons.alertTriangle;
      case 'info':
        return LucideIcons.info;
      case 'settings':
        return LucideIcons.settings;
      case 'user':
        return LucideIcons.user;
      case 'home':
        return LucideIcons.home;
      case 'search':
        return LucideIcons.search;
      case 'plus':
        return LucideIcons.plus;
      case 'x':
        return LucideIcons.x;
      case 'check':
        return LucideIcons.check;
      case 'chevron-right':
        return LucideIcons.chevronRight;
      case 'chevron-left':
        return LucideIcons.chevronLeft;
      case 'more-vertical':
        return LucideIcons.moreVertical;
      case 'filter':
        return LucideIcons.filter;
      case 'calendar':
        return LucideIcons.calendar;
      case 'clock':
        return LucideIcons.clock;
      case 'map-pin':
        return LucideIcons.mapPin;
      case 'camera':
        return LucideIcons.camera;
      case 'image':
        return LucideIcons.image;
      case 'send':
        return LucideIcons.send;
      case 'log-out':
        return LucideIcons.logOut;
      case 'bell':
        return LucideIcons.bell;
      case 'siren':
        return LucideIcons.siren;
      case 'lightbulb':
        return LucideIcons.lightbulb;
      case 'key':
        return LucideIcons.key;
      case 'tool':
        return LucideIcons.hammer;
      case 'wrench':
        return LucideIcons.wrench;
      case 'cpu':
        return LucideIcons.cpu;
      case 'server':
        return LucideIcons.server;
      case 'database':
        return LucideIcons.database;
      case 'layers':
        return LucideIcons.layers;
      case 'layout':
        return LucideIcons.layout;
      case 'list':
        return LucideIcons.list;
      case 'grid':
        return LucideIcons.grid;
      case 'activity':
        return LucideIcons.activity;
      case 'bar-chart':
        return LucideIcons.barChart2;
      case 'pie-chart':
        return LucideIcons.pieChart;
      case 'clipboard':
        return LucideIcons.clipboard;
      case 'clipboard-list':
        return LucideIcons.clipboardList;
      case 'archive':
        return LucideIcons.archive;
      case 'flag':
        return LucideIcons.flag;
      case 'bookmark':
        return LucideIcons.bookmark;
      case 'star':
        return LucideIcons.star;
      case 'heart':
        return LucideIcons.heart;
      case 'thumbs-up':
        return LucideIcons.thumbsUp;
      case 'thumbs-down':
        return LucideIcons.thumbsDown;
      case 'message-circle':
        return LucideIcons.messageCircle;
      case 'message-square':
        return LucideIcons.messageSquare;
      case 'mail':
        return LucideIcons.mail;
      case 'phone':
        return LucideIcons.phone;
      case 'video':
        return LucideIcons.video;
      case 'mic':
        return LucideIcons.mic;
      case 'volume-2':
        return LucideIcons.volume2;
      case 'volume-x':
        return LucideIcons.volumeX;
      case 'maximize':
        return LucideIcons.maximize;
      case 'minimize':
        return LucideIcons.minimize;
      case 'move':
        return LucideIcons.move;
      case 'refresh-cw':
        return LucideIcons.refreshCw;
      case 'rotate-ccw':
        return LucideIcons.rotateCcw;
      case 'rotate-cw':
        return LucideIcons.rotateCw;
      case 'download':
        return LucideIcons.download;
      case 'upload':
        return LucideIcons.upload;
      case 'share':
        return LucideIcons.share;
      case 'share-2':
        return LucideIcons.share2;
      case 'external-link':
        return LucideIcons.externalLink;
      case 'link':
        return LucideIcons.link;
      case 'power':
        return LucideIcons.power;
      case 'shield':
        return LucideIcons.shield;
      case 'shield-off':
        return LucideIcons.shieldOff;
      case 'shield-check':
        return LucideIcons.shieldCheck;
      case 'shield-alert':
        return LucideIcons.shieldAlert;
      case 'unlock':
        return LucideIcons.unlock;
      default:
        return LucideIcons.helpCircle;
    }
  }

  static const List<String> availableIcons = [
    'zap',
    'droplet',
    'building',
    'trash',
    'box',
    'wifi',
    'help-circle',
    'lock',
    'trees',
    'hard-hat',
    'file-text',
    'alert-triangle',
    'info',
    'settings',
    'user',
    'home',
    'search',
    'bell',
    'siren',
    'lightbulb',
    'key',
    'tool',
    'wrench',
    'cpu',
    'server',
    'database',
    'layers',
    'layout',
    'list',
    'grid',
    'activity',
    'bar-chart',
    'pie-chart',
    'clipboard',
    'archive',
    'flag',
    'bookmark',
    'star',
    'heart',
    'thumbs-up',
    'message-circle',
    'mail',
    'phone',
    'video',
    'mic',
    'download',
    'upload',
    'share',
    'power',
    'shield',
    'shield-check',
  ];
}
