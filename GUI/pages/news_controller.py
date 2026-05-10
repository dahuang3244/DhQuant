from __future__ import annotations

import random
from datetime import datetime, timedelta

from PySide6.QtCore import QObject, Property, Signal, Slot


_MOCK_NEWS: list[dict] = [
    {
        "id": "n001",
        "industry": "金融",
        "title": "美联储官员暗示年内或再降息一次，市场反应积极",
        "source": "Reuters",
        "time": "2026-05-10 09:15",
        "brief": "美联储多位官员在最新讲话中暗示，若通胀数据持续改善，年内不排除再次降息的可能，美股三大指数随之上扬。",
        "content": (
            "周五，美联储多位官员在公开讲话中表示，当前通胀走势令人鼓舞，若接下来几个月的CPI数据继续向2%靶位收敛，"
            "委员会将具备再次降息的政策空间。市场对此解读为鸽派信号，美股三大指数盘中均走高逾1%，10年期美债收益率"
            "小幅下行至4.28%。分析师认为，降息预期升温将对成长股估值构成支撑，尤其有利于科技板块。"
        ),
        "sentiment": "positive",
        "ai": {
            "summary": (
                "降息预期升温是本轮行情的核心驱动力。历史数据显示，降息周期初期成长股相对表现最佳，"
                "建议重点关注高估值但现金流稳健的科技龙头。债券市场的收益率下行也将利好REITs与公用事业板块。"
            ),
            "rate": 7.8,
            "advice": "逢低做多纳斯达克ETF，适度增配美债，规避强美元敏感板块",
            "tags": ["降息利好", "成长股机会", "中期布局"],
        },
    },
    {
        "id": "n002",
        "industry": "金融",
        "title": "高盛下调2026年全球GDP预测，贸易摩擦风险上升",
        "source": "Bloomberg",
        "time": "2026-05-10 08:40",
        "brief": "高盛研究部将2026年全球GDP增速预测从3.1%下调至2.7%，主要因素为贸易壁垒升级及主要经济体需求疲软。",
        "content": (
            "高盛最新报告指出，近期贸易关税升级超出预期，叠加欧洲制造业PMI持续萎缩、中国出口增速放缓，"
            "全球供应链重组摩擦成本显著上升。报告将2026年全球GDP增速由3.1%下调至2.7%，并将美国衰退概率"
            "上调至25%。大宗商品需求前景同步走弱，铜、铁矿石期货盘中大幅低开。"
        ),
        "sentiment": "negative",
        "ai": {
            "summary": (
                "贸易摩擦预期恶化是系统性风险信号，需警惕全球需求收缩对周期性资产的拖累。"
                "防御性配置需前置，黄金与低波动因子ETF值得关注。"
            ),
            "rate": 3.2,
            "advice": "减持大宗商品相关敞口，增配黄金与防御性板块，关注美元避险需求",
            "tags": ["风险规避", "防御配置", "短期谨慎"],
        },
    },
    {
        "id": "n003",
        "industry": "科技",
        "title": "英伟达发布新一代AI芯片B300，算力再提升3倍",
        "source": "The Verge",
        "time": "2026-05-10 07:55",
        "brief": "英伟达在GTC大会上正式发布Blackwell Ultra架构B300芯片，训练吞吐量较上代H100提升约300%，引发AI概念股全线走强。",
        "content": (
            "英伟达CEO黄仁勋在GTC大会发表主题演讲，正式推出B300 GPU。新芯片基于Blackwell Ultra架构，"
            "采用台积电3nm工艺，HBM4显存带宽达到18TB/s，大模型训练吞吐量较H100提升约300%，推理延迟"
            "同步压缩40%。微软、谷歌、亚马逊已确认首批采购意向。英伟达盘前涨超8%，带动费城半导体指数"
            "集体走强，AMD、TSMC等跟随上涨。"
        ),
        "sentiment": "positive",
        "ai": {
            "summary": (
                "英伟达产品迭代速度持续超预期，B300的发布将进一步巩固其在AI训练市场的垄断地位。"
                "云厂商资本开支大概率上修，带动HBM、CoWoS封装、光互联等供应链受益。"
            ),
            "rate": 9.1,
            "advice": "做多NVDA及AI算力产业链，关注HBM供应商SK海力士，台积电CoWoS产能受益标的",
            "tags": ["强烈做多", "AI主线", "产业链联动"],
        },
    },
    {
        "id": "n004",
        "industry": "科技",
        "title": "苹果WWDC 2026发布端侧AI新框架，隐私优先战略落地",
        "source": "9to5Mac",
        "time": "2026-05-09 22:10",
        "brief": "苹果在WWDC 2026上推出Apple Intelligence 2.0，强调全端侧推理能力，无需上传数据，引发AI隐私赛道关注。",
        "content": (
            "苹果在WWDC 2026上发布Apple Intelligence 2.0框架，支持在M系列芯片设备上完成100B参数量级模型"
            "的端侧推理，无需联网或数据上云。新框架深度集成Siri、FaceTime实时翻译及写作助手功能。"
            "分析师认为，苹果的端侧路线将倒逼竞争对手重构AI战略，对高通骁龙X系列芯片构成威胁，"
            "同时利好对隐私保护有强监管要求的欧洲市场渗透。"
        ),
        "sentiment": "positive",
        "ai": {
            "summary": (
                "端侧AI是未来两年竞争的核心战场，苹果的生态壁垒将转化为强大护城河。"
                "对云AI厂商形成竞争压力，但对半导体IP（如ARM）及高算力移动芯片需求构成支撑。"
            ),
            "rate": 7.4,
            "advice": "中性看多AAPL，关注ARM Holding受益逻辑，评估高通端侧业务受冲击程度",
            "tags": ["端侧AI", "生态壁垒", "中长线"],
        },
    },
    {
        "id": "n005",
        "industry": "能源",
        "title": "OPEC+维持减产协议，国际油价反弹至78美元",
        "source": "CNBC",
        "time": "2026-05-10 06:30",
        "brief": "OPEC+部长级会议决定维持现有减产政策，布伦特原油期货应声上涨2.3%，回升至78美元/桶上方。",
        "content": (
            "OPEC+周五举行部长级视频会议，沙特与俄罗斯主导通过了维持现有产量削减方案的决议，"
            "未如部分分析师预期那样进行增产。受此消息提振，布伦特原油期货上涨2.3%至78.4美元/桶，"
            "WTI原油同步反弹至74.6美元/桶。能源股板块随即走强，埃克森美孚、雪佛龙盘前均涨逾1.5%。"
            "然而，需求侧隐忧仍存，IEA最新报告显示全球石油需求增速正在放缓。"
        ),
        "sentiment": "positive",
        "ai": {
            "summary": (
                "OPEC+维持减产是短期油价的托底力量，但需求端放缓制约上行空间。"
                "油价在75-82美元区间震荡的概率较高，能源股短期受益但中期需跟踪需求数据。"
            ),
            "rate": 6.0,
            "advice": "短线做多原油ETF与能源龙头，目标价位82美元附近减仓，关注IEA需求数据验证",
            "tags": ["短线机会", "原油反弹", "区间操作"],
        },
    },
    {
        "id": "n006",
        "industry": "能源",
        "title": "欧盟批准1200亿欧元绿色能源补贴计划，光伏风电股大涨",
        "source": "Financial Times",
        "time": "2026-05-09 18:45",
        "brief": "欧盟委员会正式批准1200亿欧元清洁能源补贴方案，覆盖光伏、风电、储能及氢能领域，为期五年。",
        "content": (
            "欧盟委员会周四正式批准\"绿色主权基金\"补贴计划，总规模1200亿欧元，将在2026至2030年间分批注入"
            "光伏、海上风电、电池储能及绿氢生产领域。其中德国、西班牙、法国为主要受益国。"
            "消息公布后，隆基绿能、晶科能源、维斯塔斯等在欧有大量业务的企业股价盘中均涨超5%。"
        ),
        "sentiment": "positive",
        "ai": {
            "summary": (
                "欧盟大规模政策补贴将为清洁能源企业提供持续订单支撑，尤其利好光伏组件与储能系统供应商。"
                "绿氢赛道的政策催化也值得持续跟踪，相关ETF可作为中线配置工具。"
            ),
            "rate": 8.3,
            "advice": "增配全球清洁能源ETF，重点关注欧洲市场敞口大的光伏组件与海上风机龙头",
            "tags": ["政策利好", "清洁能源", "中线布局"],
        },
    },
    {
        "id": "n007",
        "industry": "医疗",
        "title": "FDA批准礼来新型GLP-1药物，覆盖肥胖与非酒精性脂肪肝",
        "source": "STAT News",
        "time": "2026-05-10 05:00",
        "brief": "FDA批准礼来研发的新一代GLP-1/GIP双靶点药物orforglipron，适应症新增非酒精性脂肪性肝炎（NASH），礼来盘前涨超6%。",
        "content": (
            "美国FDA周五批准礼来（Eli Lilly）研发的口服小分子GLP-1/GIP双受体激动剂orforglipron上市，"
            "适应症覆盖成人肥胖及2型糖尿病，并在补充申请中获批NASH（非酒精性脂肪性肝炎）辅助治疗适应症，"
            "这是FDA首次批准GLP-1药物用于肝病治疗。礼来盘前股价大涨6.2%，诺和诺德同步上涨，而部分"
            "NASH靶向药公司如Madrigal跌超8%，受益赛道受到冲击。"
        ),
        "sentiment": "positive",
        "ai": {
            "summary": (
                "GLP-1药物适应症持续扩展是本轮医药牛市的核心主线，礼来凭借口服剂型与NASH双适应症"
                "进一步拉开与竞争对手的差距。中国GLP-1管线企业（华东医药、信达生物）的国内准入时间节点值得关注。"
            ),
            "rate": 8.9,
            "advice": "做多礼来（LLY），择机布局中国GLP-1受益标的，评估NASH赛道受冲击个股的超跌机会",
            "tags": ["强烈做多", "GLP-1主线", "跨市场联动"],
        },
    },
    {
        "id": "n008",
        "industry": "医疗",
        "title": "辉瑞削减2026年研发预算15%，聚焦肿瘤学核心管线",
        "source": "Wall Street Journal",
        "time": "2026-05-09 20:30",
        "brief": "辉瑞宣布将2026年研发预算削减约15%，关闭多个早期项目，集中资源押注ADC抗体偶联药物与mRNA肿瘤疫苗。",
        "content": (
            "辉瑞CEO周四在投资者日活动上宣布重大战略调整，公司将2026年研发支出从预算的112亿美元削减至95亿美元，"
            "关闭约30个处于临床前或一期阶段的项目，聚焦ADC（抗体偶联药物）与mRNA肿瘤治疗性疫苗两条核心赛道。"
            "市场对此反应分化：削减成本的短期逻辑推动股价微涨0.8%，但部分分析师担忧管线瘦身将削弱中期增长动能。"
        ),
        "sentiment": "neutral",
        "ai": {
            "summary": (
                "辉瑞的战略收缩是典型的\"砍枝强干\"策略，短期有利于提升资本效率，但管线多样性降低。"
                "ADC赛道竞争激烈（AZ、第一三共、罗氏均有重磅品种），辉瑞能否后发制人需持续跟踪临床数据。"
            ),
            "rate": 5.0,
            "advice": "对辉瑞持中性观望态度，重点关注ADC管线里程碑事件，年内核心数据读出是关键催化剂",
            "tags": ["中性观望", "ADC赛道", "里程碑跟踪"],
        },
    },
    {
        "id": "n009",
        "industry": "消费",
        "title": "五一消费数据超预期，国内旅游收入同比增长22%",
        "source": "新华社",
        "time": "2026-05-08 10:00",
        "brief": "文旅部数据显示，2026年五一假期国内旅游总收入达7680亿元，同比增长22.4%，出行人次刷新历史纪录。",
        "content": (
            "文化和旅游部发布五一假期旅游市场综合数据：全国共接待国内旅游出行人次约4.5亿，同比增长18.6%；"
            "旅游收入7680亿元，同比增长22.4%，较疫情前2019年同期增长51%。出境游方面，港澳台及周边国家"
            "线路预订量同比增长约35%。酒店、航空、景区股盘中集体拉升，中国中免、中青旅领涨消费板块。"
        ),
        "sentiment": "positive",
        "ai": {
            "summary": (
                "消费数据超预期印证内需复苏的韧性，旅游、餐饮、免税等场景消费受益最为直接。"
                "五一数据将为二季度GDP提供正贡献，有助于缓解市场对内需疲软的担忧。"
            ),
            "rate": 7.6,
            "advice": "增配免税（中国中免）、酒店（首旅、锦江）、景区（宋城、丽江）等出行消费标的",
            "tags": ["内需复苏", "消费场景", "短线催化"],
        },
    },
    {
        "id": "n010",
        "industry": "工业",
        "title": "工信部推动工业机器人国产化提速，2026年渗透率目标超60%",
        "source": "工信部官网",
        "time": "2026-05-09 15:30",
        "brief": "工信部发布专项行动方案，明确2026年工业机器人国产品牌市场占有率目标超过60%，并设立50亿元专项引导基金。",
        "content": (
            "工信部联合财政部发布《工业机器人国产化攻坚专项行动方案》，明确到2026年底，工业机器人国产品牌"
            "市场占有率达到60%以上。方案设立50亿元国家引导基金，支持关节减速器、伺服电机、控制器等核心零部件"
            "国产替代突破。埃斯顿、汇川技术、绿的谐波等相关标的盘中集体涨停，带动机器人ETF单日涨幅超4%。"
        ),
        "sentiment": "positive",
        "ai": {
            "summary": (
                "政策驱动的国产替代浪潮下，工业机器人核心零部件是最确定性的受益方向。"
                "关节减速器（绿的谐波）、伺服系统（汇川技术）、本体集成（埃斯顿）构成完整产业链投资链条。"
            ),
            "rate": 8.5,
            "advice": "重点配置机器人核心零部件龙头，关注机器人ETF（562500）作为指数化配置工具",
            "tags": ["政策驱动", "国产替代", "产业链布局"],
        },
    },
]

_INDUSTRIES = ["全部", "金融", "科技", "能源", "医疗", "消费", "工业"]


class NewsController(QObject):
    stateChanged = Signal()
    newsListChanged = Signal()
    selectedChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._industry = "全部"
        self._loading = False
        self._selected_id = _MOCK_NEWS[0]["id"] if _MOCK_NEWS else ""
        self._last_refresh = datetime.now().strftime("%H:%M:%S")

    @Property(str, notify=stateChanged)
    def industry(self) -> str:
        return self._industry

    @Property(bool, notify=stateChanged)
    def loading(self) -> bool:
        return self._loading

    @Property(str, notify=selectedChanged)
    def selectedId(self) -> str:
        return self._selected_id

    @Property(str, notify=stateChanged)
    def lastRefresh(self) -> str:
        return self._last_refresh

    @Property("QVariantList", notify=newsListChanged)
    def newsList(self) -> list[dict]:
        if self._industry == "全部":
            return _MOCK_NEWS
        return [n for n in _MOCK_NEWS if n["industry"] == self._industry]

    @Property("QVariantMap", notify=selectedChanged)
    def selectedNews(self) -> dict:
        for item in _MOCK_NEWS:
            if item["id"] == self._selected_id:
                return item
        return {}

    @Property("QVariantList", notify=stateChanged)
    def industries(self) -> list[str]:
        return _INDUSTRIES

    @Slot(str)
    def setIndustry(self, value: str) -> None:
        if value == self._industry:
            return
        self._industry = value
        self.stateChanged.emit()
        self.newsListChanged.emit()

    @Slot(str)
    def selectNews(self, news_id: str) -> None:
        if news_id == self._selected_id:
            return
        self._selected_id = news_id
        self.selectedChanged.emit()

    @Slot()
    def refresh(self) -> None:
        self._loading = True
        self.stateChanged.emit()
        self._last_refresh = datetime.now().strftime("%H:%M:%S")
        self._loading = False
        self.stateChanged.emit()
        self.newsListChanged.emit()
